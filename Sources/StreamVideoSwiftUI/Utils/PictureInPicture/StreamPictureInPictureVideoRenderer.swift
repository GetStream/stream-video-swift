//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamWebRTC
import Foundation
import Combine
import StreamVideo

/// A view that can be used to render an instance of `RTCVideoTrack`
final class StreamPictureInPictureVideoRenderer: UIView, RTCVideoRenderer {

    /// The rendering track.
    var track: RTCVideoTrack? {
        didSet {
            // Whenever the track changes we perform the following operations if possible:
            // - stopFrameStreaming for the old track
            // - startFrameStreaming for the new track and only if we are already
            // in Picture in Picture.
            guard oldValue != track else { return }
            prepareForTrackRendering(oldValue)
        }
    }

    /// The layer that renders the track's frames.
    var displayLayer: CALayer { contentView.sampleBufferDisplayLayer }

    /// The publisher which is used to streamline the frames received from the track.
    private let bufferPublisher: PassthroughSubject<CMSampleBuffer, Never> = .init()

    /// The view that contains the rendering layer.
    private lazy var contentView: SampleBufferVideoCallView = {
        let contentView = SampleBufferVideoCallView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.contentMode = .scaleAspectFill
        contentView.sampleBufferDisplayLayer.videoGravity = .resizeAspectFill
        contentView.sampleBufferDisplayLayer.preventsDisplaySleepDuringVideoPlayback = true
        return contentView
    }()

    /// The transformer used to transform and downsample a RTCVideoFrame's buffer.
    private var bufferTransformer = StreamBufferTransformer()

    /// The cancellable used to control the bufferPublisher stream.
    private var bufferUpdatesCancellable: AnyCancellable?

    /// The view's size.
    /// - Note: We are using this property instead for `frame.size` or `bounds.size` so we can
    /// access it from any thread.
    private var contentSize: CGSize = .zero

    /// The track's size.
    private var trackSize: CGSize = .zero {
        didSet {
            guard trackSize != oldValue else { return  }
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
    private var framesToSkip = 1

    /// The number of frames that we have skipped so far. This is used as a step counter in the
    /// ``renderFrame(_:)``.
    private var framesSkipped = 0

    /// A size ratio threshold used to determine if resizing is required.
    let sizeRatioThreshold: CGFloat = 2

    // MARK: - Lifecycle

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        // Depending on the window we are moving we either start or stop
        // streaming frames from the track.
        if newWindow != nil {
            startFrameStreaming(for: track, on: newWindow)
        } else {
            stopFrameStreaming(for: track)
        }
        super.willMove(toWindow: newWindow)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentSize = frame.size
    }

    // MARK: - Rendering lifecycle

    /// This method is being called from WebRTC and asks the container to set its size to the track's size.
    func setSize(_ size: CGSize) {
        trackSize = size
    }

    func renderFrame(_ frame: RTCVideoFrame?) {
        guard let frame = frame else {
            return
        }

        // Update the trackSize and re-calculate rendering properties if the size
        // has changed.
        trackSize = .init(width: Int(frame.width), height: Int(frame.height))

        defer {
            handleFrameSkippingIfRequired()
        }

        // We render frames every time the stepper/counter value is 0.
        guard framesSkipped == 0 else {
            return
        }

        if
            let pixelBuffer = frame.buffer as? RTCCVPixelBuffer,
            let sampleBuffer = bufferTransformer.transform(pixelBuffer.pixelBuffer)
        {
            bufferPublisher.send(sampleBuffer)
        } else if
            let i420buffer = frame.buffer as? RTCI420Buffer,
            let transformedBuffer = bufferTransformer.transform(i420buffer, targetSize: contentSize),
            let sampleBuffer = bufferTransformer.transform(transformedBuffer)
        {
            bufferPublisher.send(sampleBuffer)
        } else {
            log.warning("Failed to convert \(type(of: frame.buffer)) CMSampleBuffer.")
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
        guard let trackId = track?.trackId else {
            contentView.sampleBufferDisplayLayer.flush()
            return
        }

        if #available(iOS 14.0, *) {
            if contentView.sampleBufferDisplayLayer.requiresFlushToResumeDecoding == true {
                contentView.sampleBufferDisplayLayer.flush()
                log.debug("Display layer for track:\(trackId) flushed ✅")
            }
        }

        if #available(iOS 17.0, *) {
            if contentView.sampleBufferDisplayLayer.sampleBufferRenderer.isReadyForMoreMediaData {
                contentView.sampleBufferDisplayLayer.sampleBufferRenderer.enqueue(buffer)
            }
        } else {
            if contentView.sampleBufferDisplayLayer.isReadyForMoreMediaData {
                contentView.sampleBufferDisplayLayer.enqueue(buffer)
            }
        }

    }

    /// A method used to start consuming frames from the track.
    /// - Note: In order to avoid unnecessary processing, we only start consuming track's frames when
    /// the view has been added on a window (which means that Picture in Picture view is visible).
    private func startFrameStreaming(
        for track: RTCVideoTrack?,
        on window: UIWindow?
    ) {
        guard window != nil, let track else { return }

        bufferUpdatesCancellable = bufferPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.process($0) }

        track.add(self)
    }

    /// A method that stops the frame consumption from the track. Used automatically when the rendering
    /// view move's away from the window or when the track changes.
    private func stopFrameStreaming(for track: RTCVideoTrack?) {
        bufferUpdatesCancellable?.cancel()
        track?.remove(self)
    }

    /// A method used to calculate rendering required properties, every time the trackSize changes.
    private func didUpdateTrackSize() {
        guard contentSize != .zero else { return }

        let widthDiffRatio = trackSize.width / contentSize.width
        let heightDiffRatio = trackSize.height / contentSize.height
        requiresResize = widthDiffRatio >= sizeRatioThreshold || heightDiffRatio >= sizeRatioThreshold
        framesToSkip = requiresResize ? max(Int(min(Int(widthDiffRatio), Int(heightDiffRatio)) / 2), 1) : 1
        framesSkipped = 0
        log.debug("contentSize:\(contentSize), trackId:\(track?.trackId ?? "n/a") trackSize:\(trackSize) requiresResize:\(requiresResize) framesToSkip:\(framesToSkip) framesSkipped:\(framesSkipped)")
    }

    /// A method used to handle the frameSkipping(step) during frame consumption.
    private func handleFrameSkippingIfRequired() {
        if framesToSkip > 0 {
            if framesSkipped == framesToSkip {
                framesSkipped = 0
            } else {
                framesSkipped += 1
            }
            log.debug("framesToSkip:\(framesToSkip) framesSkipped:\(framesSkipped)")
        } else if framesSkipped > 0 {
            framesSkipped = 0
        }
    }

    /// A method used to prepare the view for a new track rendering.
    private func prepareForTrackRendering(_ oldValue: RTCVideoTrack?) {
        stopFrameStreaming(for: oldValue)
        framesToSkip = 0
        framesSkipped = 0
        requiresResize = false
        startFrameStreaming(for: track, on: window)
    }
}
