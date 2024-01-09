//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamWebRTC
import Foundation
import Combine
import StreamVideo

final class StreamPictureInPictureVideoRenderer: UIView, RTCVideoRenderer {

    var track: RTCVideoTrack? {
        didSet {
            guard oldValue != track else { return }
            stopPictureInPicture(for: oldValue)
            startPictureInPicture(for: track, on: window)
        }
    }

    private var scaleFactor: CGFloat = 1

    private let bufferPublisher: PassthroughSubject<CMSampleBuffer, Never> = .init()

    private lazy var contentView: SampleBufferVideoCallView = {
        let contentView = SampleBufferVideoCallView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.contentMode = .scaleAspectFill
        contentView.sampleBufferDisplayLayer.videoGravity = .resizeAspectFill
        contentView.sampleBufferDisplayLayer.preventsDisplaySleepDuringVideoPlayback = true
        return contentView
    }()

    private var bufferUpdatesCancellable: AnyCancellable?

    // MARK: - Lifecycle

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        if newWindow != nil {
            startPictureInPicture(for: track, on: newWindow)
        } else {
            stopPictureInPicture(for: track)
        }
        super.willMove(toWindow: newWindow)
    }

    // MARK: - Rendering lifecycle

    func setSize(_ size: CGSize) {
        scaleFactor = size.height > size.width
        ? size.height / size.width
        : size.width / size.height
    }

    func renderFrame(_ frame: RTCVideoFrame?) {
        guard let frame = frame else {
            return
        }

        if let pixelBuffer = frame.buffer as? RTCCVPixelBuffer {
            guard let sampleBuffer = CMSampleBuffer.from(pixelBuffer.pixelBuffer) else {
                log.warning("Failed to convert CVPixelBuffer to CMSampleBuffer")
                return
            }

            bufferPublisher.send(sampleBuffer)
        } else if let i420buffer = frame.buffer as? RTCI420Buffer {
            // We reduce the track resolution, since it's displayed in a smaller place.
            // Values are picked depending on how much the PiP view takes in an average iPhone or iPad.
            let reductionFactor = 2
            guard let buffer = convertI420BufferToPixelBuffer(i420buffer, reductionFactor: reductionFactor),
                  let sampleBuffer = CMSampleBuffer.from(buffer) else {
                return
            }

            bufferPublisher.send(sampleBuffer)
        }
    }

    // MARK: - Private helpers

    private func setUp() {
        addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func process(_ buffer: CMSampleBuffer) {
        guard let trackId = track?.trackId else {
            contentView.sampleBufferDisplayLayer.flush()
            return
        }

        if #available(iOS 14.0, *) {
            if contentView.sampleBufferDisplayLayer.requiresFlushToResumeDecoding == true {
                contentView.sampleBufferDisplayLayer.flush()
                log.debug("→ Display layer for track:\(trackId) flushed ✅")
            }
        }
        if contentView.sampleBufferDisplayLayer.isReadyForMoreMediaData == true {
            contentView.sampleBufferDisplayLayer.enqueue(buffer)
        }
    }

    private func startPictureInPicture(
        for track: RTCVideoTrack?,
        on window: UIWindow?
    ) {
        guard window != nil, let track else { return }

        bufferUpdatesCancellable = bufferPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.process($0) }

        track.add(self)
    }

    private func stopPictureInPicture(for track: RTCVideoTrack?) {
        bufferUpdatesCancellable?.cancel()
        track?.remove(self)
    }
}
