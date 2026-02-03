//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

final class ExternalSourceCaptureHandler: StreamVideoCapturerActionHandler, @unchecked Sendable {

    private struct Session {
        var videoSource: RTCVideoSource
        var videoCapturer: RTCVideoCapturer
        var videoCapturerDelegate: RTCVideoCapturerDelegate
    }

    private let sessionReadyCallback: @Sendable (ExternalFrameSink) -> Void
    private var activeSession: Session?

    init(sessionReadyCallback: @escaping @Sendable (ExternalFrameSink) -> Void) {
        self.sessionReadyCallback = sessionReadyCallback
    }

    func handle(_ action: StreamVideoCapturer.Action) async throws {
        switch action {
        case let .startCapture(_, dimensions, frameRate, videoSource, videoCapturer, videoCapturerDelegate, _):
            guard activeSession == nil else { return }
            activeSession = Session(
                videoSource: videoSource,
                videoCapturer: videoCapturer,
                videoCapturerDelegate: videoCapturerDelegate
            )
            let frameSink = ExternalSourceFrameSink(
                capturer: videoCapturer,
                delegate: videoCapturerDelegate
            )
            sessionReadyCallback(frameSink)
            log.debug("\(type(of: self)) session ready for external frames (dimensions: \(dimensions), frameRate: \(frameRate)).", subsystems: .videoCapturer)
        case .stopCapture:
            activeSession = nil
            log.debug("\(type(of: self)) stopped.", subsystems: .videoCapturer)
        default:
            break
        }
    }
}

private final class ExternalSourceFrameSink: ExternalFrameSink, @unchecked Sendable {
    private let capturer: RTCVideoCapturer
    private let delegate: RTCVideoCapturerDelegate

    init(capturer: RTCVideoCapturer, delegate: RTCVideoCapturerDelegate) {
        self.capturer = capturer
        self.delegate = delegate
    }

    func pushFrame(pixelBuffer: CVPixelBuffer, rotation: ExternalVideoRotation) {
        let timeStampNs = Int64(ProcessInfo.processInfo.systemUptime * Double(NSEC_PER_SEC))
        let rtcBuffer = RTCCVPixelBuffer(pixelBuffer: pixelBuffer)
        let rtcFrame = RTCVideoFrame(
            buffer: rtcBuffer,
            rotation: rotation.rtcRotation,
            timeStampNs: timeStampNs
        )
        delegate.capturer(capturer, didCapture: rtcFrame)
    }
}
