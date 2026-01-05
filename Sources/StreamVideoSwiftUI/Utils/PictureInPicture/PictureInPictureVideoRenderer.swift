//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
import StreamWebRTC

/// A view that can be used to render an instance of `RTCVideoTrack`
final class PictureInPictureVideoRenderer: UIView, RTCVideoRenderer {

    let store: PictureInPictureStore

    var participant: CallParticipant

    /// The rendering track.
    var track: RTCVideoTrack? {
        didSet {
            // Whenever the track changes we perform the following operations if possible:
            // - stopFrameStreaming for the old track
            // - startFrameStreaming for the new track and only if we are already
            // in picture-in-picture.
            guard oldValue != track else { return }
            prepareForTrackRendering(oldValue)
        }
    }

    /// The publisher which is used to streamline the frames received from the track.
    private let bufferPublisher: PassthroughSubject<CMSampleBuffer, Never> = .init()

    /// The view that contains the rendering layer.
    private lazy var contentView: SampleBufferVideoCallView = {
        let contentView = SampleBufferVideoCallView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.contentMode = .scaleAspectFill
        contentView.videoGravity = .resizeAspectFill
        contentView.preventsDisplaySleepDuringVideoPlayback = true
        return contentView
    }()

    /// The transformer used to transform and downsample a RTCVideoFrame's buffer.
    private var bufferTransformer = PictureInPictureBufferTransformer()

    /// The cancellable used to control the bufferPublisher stream.
    private var bufferUpdatesCancellable: AnyCancellable?

    /// The view's size.
    /// - Note: We are using this property instead for `frame.size` or `bounds.size` so we can
    /// access it from any thread.
    private var contentSize: CGSize = .zero

    /// The track's size.
    private var trackSize: CGSize = .zero {
        didSet {
            guard trackSize != oldValue else { return }
            didUpdateTrackSize()
        }
    }

    /// A property that defines if the RTCVideoFrame instances that will be rendered need to be resized
    /// to fid the view's contentSize.
    private var requiresResize = false {
        didSet { bufferTransformer.requiresResize = requiresResize }
    }

    /// As we are operate in smaller rendering bounds we skip frames depending on this property's value
    /// to improve performance.
    /// - Note: The number of frames to skip is being calculated based on the ``trackSize`` and
    /// ``contentSize``. It takes into account also the ``sizeRatioThreshold``
    private var noOfFramesToSkipAfterRendering = 1

    /// The number of frames that we have skipped so far. This is used as a step counter in the
    /// ``renderFrame(_:)``.
    private var skippedFrames = 0

    /// We render frames every time the stepper/counter value is 0 and have a valid trackSize.
    private var shouldRenderFrame: Bool { skippedFrames == 0 && trackSize != .zero }

    /// A size ratio threshold used to determine if resizing is required.
    /// - Note: It seems that Picture-in-Picture doesn't like rendering frames that are bigger than its
    /// window size. For this reason, we are setting the resizeThreshold to `1`.
    private let resizeRequiredSizeRatioThreshold: CGFloat = 1

    /// A size ratio threshold used to determine if skipping frames is required.
    private let sizeRatioThreshold: CGFloat = 15

    private let isLoggingEnabled = false

    private let disposableBag = DisposableBag()

    // MARK: - Lifecycle

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    init(
        store: PictureInPictureStore,
        participant: CallParticipant,
        track: RTCVideoTrack?
    ) {
        self.store = store
        self.participant = participant
        self.track = track
        super.init(frame: .zero)
        setUp()
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        // Depending on the window we are moving we either start or stop
        // streaming frames from the track.
        if newWindow != nil {
            startFrameStreaming(for: track, on: newWindow)
        } else {
            stopFrameStreaming(for: track)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentSize = frame.size
    }

    // MARK: - Rendering lifecycle

    /// This method is being called from WebRTC and asks the container to set its size to the track's size.
    nonisolated func setSize(_ size: CGSize) {
        Task(disposableBag: disposableBag) { @MainActor [weak self] in
            guard let self else { return }
            trackSize = size
        }
    }

    nonisolated func renderFrame(_ frame: RTCVideoFrame?) {
        Task(disposableBag: disposableBag) { @MainActor [weak self] in
            guard let self, let frame = frame else {
                return
            }

            // Update the trackSize and re-calculate rendering properties if the size
            // has changed.
            trackSize = .init(width: Int(frame.width), height: Int(frame.height))

            logMessage(
                .debug,
                message: "→ Received frame with trackSize:\(trackSize)"
            )

            defer {
                handleFrameSkippingIfRequired()
            }

            guard shouldRenderFrame else {
                logMessage(.debug, message: "→ Skipping frame.")
                return
            }

            if
                let yuvBuffer = bufferTransformer.transformAndResizeIfRequired(frame, targetSize: contentSize)?
                .buffer as? StreamRTCYUVBuffer,
                let sampleBuffer = yuvBuffer.sampleBuffer {
                logMessage(
                    .debug,
                    message: "➕ Buffer for trackId:\(track?.trackId ?? "n/a") added."
                )
                bufferPublisher.send(sampleBuffer)
            } else {
                logMessage(
                    .warning,
                    message: "Failed to convert \(type(of: frame.buffer)) CMSampleBuffer."
                )
            }
        }
    }

    // MARK: - Private helpers

    /// Set up the view's hierarchy.
    private func setUp() {
        addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    /// A method used to process the frame's buffer and enqueue on the rendering view.
    private func process(_ buffer: CMSampleBuffer) {
        guard
            bufferUpdatesCancellable != nil,
            let trackId = track?.trackId,
            buffer.isValid
        else {
            contentView.renderingComponent.flush()
            logMessage(.debug, message: "🔥 Display layer flushed.")
            return
        }

        logMessage(
            .debug,
            message: "⚙️ Processing buffer for trackId:\(trackId)."
        )
        if #available(iOS 14.0, *) {
            if contentView.renderingComponent.requiresFlushToResumeDecoding == true {
                contentView.renderingComponent.flush()
                logMessage(.debug, message: "🔥 Display layer for track:\(trackId) flushed.")
            }
        }

        if contentView.renderingComponent.isReadyForMoreMediaData {
            contentView.renderingComponent.enqueue(buffer)
            logMessage(.debug, message: "✅ Buffer for trackId:\(trackId) enqueued.")
        }
    }

    /// A method used to start consuming frames from the track.
    /// - Note: In order to avoid unnecessary processing, we only start consuming track's frames when
    /// the view has been added on a window (which means that picture-in-picture view is visible).
    private func startFrameStreaming(
        for track: RTCVideoTrack?,
        on window: UIWindow?
    ) {
        guard window != nil, let track else { return }

        bufferUpdatesCancellable = bufferPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.process($0) }

        track.add(self)
        logMessage(
            .debug,
            message: "⏳ Frame streaming for Picture-in-Picture started."
        )
    }

    /// A method that stops the frame consumption from the track. Used automatically when the rendering
    /// view move's away from the window or when the track changes.
    private func stopFrameStreaming(for track: RTCVideoTrack?) {
        guard bufferUpdatesCancellable != nil else { return }
        bufferUpdatesCancellable?.cancel()
        bufferUpdatesCancellable = nil
        track?.remove(self)
        contentView.renderingComponent.flush()
        logMessage(.debug, message: "Frame streaming for Picture-in-Picture stopped.")
    }

    /// A method used to calculate rendering required properties, every time the trackSize changes.
    private func didUpdateTrackSize() {
        guard contentSize != .zero, trackSize != .zero else { return }

        let widthDiffRatio = trackSize.width / contentSize.width
        let heightDiffRatio = trackSize.height / contentSize.height
        requiresResize = widthDiffRatio >= resizeRequiredSizeRatioThreshold || heightDiffRatio >= resizeRequiredSizeRatioThreshold
        let requiresFramesSkipping = widthDiffRatio >= sizeRatioThreshold || heightDiffRatio >= sizeRatioThreshold

        /// Skipping frames is decided based on how much bigger is the incoming frame's size compared
        /// to PiP window's size.
        noOfFramesToSkipAfterRendering = requiresFramesSkipping
            ? max(Int(max(Int(widthDiffRatio), Int(heightDiffRatio)) / 2), 1)
            : 0

        skippedFrames = 0

        store.dispatch(.setPreferredContentSize(trackSize))

        logMessage(
            .debug,
            message:
            """
            contentSize:\(contentSize)
            trackId:\(track?.trackId ?? "n/a")
            trackSize:\(trackSize)
            requiresResize:\(requiresResize)
            noOfFramesToSkipAfterRendering:\(noOfFramesToSkipAfterRendering)
            skippedFrames:\(skippedFrames)
            widthDiffRatio:\(widthDiffRatio)
            heightDiffRatio:\(heightDiffRatio)
            """
        )
    }

    /// A method used to handle the frameSkipping(step) during frame consumption.
    private func handleFrameSkippingIfRequired() {
        if noOfFramesToSkipAfterRendering > 0 {
            if skippedFrames == noOfFramesToSkipAfterRendering {
                skippedFrames = 0
            } else {
                skippedFrames += 1
            }
            logMessage(
                .debug,
                message: "noOfFramesToSkipAfterRendering:\(noOfFramesToSkipAfterRendering) skippedFrames:\(skippedFrames)"
            )
        } else if skippedFrames > 0 {
            skippedFrames = 0
        }
    }

    /// A method used to prepare the view for a new track rendering.
    private func prepareForTrackRendering(_ oldValue: RTCVideoTrack?) {
        stopFrameStreaming(for: oldValue)
        noOfFramesToSkipAfterRendering = 0
        skippedFrames = 0
        requiresResize = false
        startFrameStreaming(for: track, on: window)
    }

    private func logMessage(
        _ level: LogLevel,
        message: String,
        error: Error? = nil,
        file: StaticString = #file,
        functionName: StaticString = #function,
        line: UInt = #line
    ) {
        guard isLoggingEnabled else {
            return
        }
        log.log(
            level,
            functionName: functionName,
            fileName: file,
            lineNumber: line,
            message: message,
            subsystems: .pictureInPicture,
            error: error
        )
    }
}
