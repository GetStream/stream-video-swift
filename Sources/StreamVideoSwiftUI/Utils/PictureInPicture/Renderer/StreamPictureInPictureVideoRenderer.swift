//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
import StreamWebRTC

/// A view that can be used to render an instance of `RTCVideoTrack`
final class StreamPictureInPictureVideoRenderer: UIView {

    /// The layer that renders the track's frames.
    private var displayLayer: CALayer { contentView.layer }

    private let dataPipeline: PictureInPictureDataPipeline

    /// The cancellable used to control the bufferPublisher stream.
    private var bufferUpdatesCancellable: AnyCancellable?

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
    private var bufferTransformer = StreamBufferTransformer()

    private let isLoggingEnabled = false

    // MARK: - Lifecycle

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    init(dataPipeline: PictureInPictureDataPipeline) {
        self.dataPipeline = dataPipeline
        super.init(frame: .zero)
        setUp()
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        // Depending on the window we are moving we either start or stop
        // streaming frames from the track.
        if newWindow != nil {
            bufferUpdatesCancellable?.cancel()
            bufferUpdatesCancellable = dataPipeline
                .frameBufferPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.process($0) }
        } else {
            bufferUpdatesCancellable?.cancel()
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
            buffer.isValid
        else {
            contentView.renderingComponent.flush()
            logMessage(.debug, message: "🔥 Display layer flushed.")
            return
        }

        logMessage(
            .debug,
            message: "⚙️ Processing buffer."
        )
        if #available(iOS 14.0, *) {
            if contentView.renderingComponent.requiresFlushToResumeDecoding == true {
                contentView.renderingComponent.flush()
                logMessage(.debug, message: "🔥 Display layer flushed.")
            }
        }

        if contentView.renderingComponent.isReadyForMoreMediaData {
            contentView.renderingComponent.enqueue(buffer)
            logMessage(.debug, message: "✅ Buffer enqueued.")
        }
    }

    private func logMessage(
        _ level: LogLevel,
        message: String,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        guard isLoggingEnabled else {
            return
        }
        log.log(
            level,
            functionName: function,
            fileName: file,
            lineNumber: line,
            message: message,
            subsystems: .pictureInPicture,
            error: nil
        )
    }
}
