//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import ReplayKit
import StreamWebRTC

final class ScreenShareStartCaptureHandler: StreamVideoCapturerActionHandler, @unchecked Sendable {

    private let recorder: RPScreenRecorder
    private var activeSession: Session?

    private struct Session {
        var videoCapturer: RTCVideoCapturer
        var videoCapturerDelegate: RTCVideoCapturerDelegate
    }

    init(
        recorder: RPScreenRecorder = .shared()
    ) {
        self.recorder = recorder
    }

    // MARK: - StreamVideoCapturerActionHandler

    func handle(_ action: StreamVideoCapturer.Action) async throws {
        switch action {
        case let .startCapture(_, _, _, _, videoCapturer, videoCapturerDelegate):
            try await execute(
                videoCapturer: videoCapturer,
                videoCapturerDelegate: videoCapturerDelegate
            )
        case .stopCapture:
            activeSession = nil
        default:
            break
        }
    }

    // MARK: Private

    private func execute(
        videoCapturer: RTCVideoCapturer,
        videoCapturerDelegate: RTCVideoCapturerDelegate
    ) async throws {
        guard !recorder.isRecording else {
            log.debug(
                "\(type(of: self)) performed no action as recording is in progress.",
                subsystems: .videoCapturer
            )
            return
        }

        // We disable the microphone as we don't support .screenshareAudio tracks
        recorder.isMicrophoneEnabled = false

        try await withCheckedThrowingContinuation { [weak self] continuation in
            guard
                let recorder = self?.recorder
            else {
                continuation.resume()
                return
            }

            self?.activeSession = .init(
                videoCapturer: videoCapturer,
                videoCapturerDelegate: videoCapturerDelegate
            )

            recorder.startCapture { [weak self] sampleBuffer, sampleBufferType, error in
                self?.didReceive(
                    sampleBuffer: sampleBuffer,
                    sampleBufferType: sampleBufferType,
                    error: error
                )
            } completionHandler: { error in
                if let error {
                    self?.activeSession = nil
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func didReceive(
        sampleBuffer: CMSampleBuffer,
        sampleBufferType: RPSampleBufferType,
        error: Error?
    ) {
        guard
            let activeSession = self.activeSession
        else {
            log.warning(
                "\(type(of: self)) received sample buffer but no active session was found.",
                subsystems: .videoCapturer
            )
            return
        }

        guard
            sampleBufferType == .video
        else {
            log.warning(
                "\(type(of: self)) only video sample buffers are supported. Received \(sampleBufferType).",
                subsystems: .videoCapturer
            )
            return
        }

        guard
            CMSampleBufferGetNumSamples(sampleBuffer) == 1,
            CMSampleBufferIsValid(sampleBuffer),
            CMSampleBufferDataIsReady(sampleBuffer)
        else {
            log.debug(
                "\(type(of: self)) screenshare video sample buffer is invalid or not ready.",
                subsystems: .videoCapturer
            )
            return
        }

        guard
            let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        else {
            log.debug(
                "\(type(of: self)) unable to extract pixel buffer from sample buffer.",
                subsystems: .videoCapturer
            )
            return
        }

        let timeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let timeStampNs = Int64(CMTimeGetSeconds(timeStamp) * Double(NSEC_PER_SEC))

        let rtcBuffer = RTCCVPixelBuffer(pixelBuffer: pixelBuffer)
        let rtcFrame = RTCVideoFrame(
            buffer: rtcBuffer,
            rotation: ._0,
            timeStampNs: timeStampNs
        )

        activeSession.videoCapturerDelegate.capturer(
            activeSession.videoCapturer,
            didCapture: rtcFrame
        )
    }
}
