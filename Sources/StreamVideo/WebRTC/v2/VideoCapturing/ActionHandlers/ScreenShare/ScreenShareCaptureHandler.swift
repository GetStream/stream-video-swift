//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import ReplayKit
import StreamWebRTC

final class ScreenShareCaptureHandler: NSObject, StreamVideoCapturerActionHandler, RPScreenRecorderDelegate, @unchecked Sendable {

    @Atomic private var isRecording: Bool = false
    private var activeSession: Session?
    private let recorder: RPScreenRecorder

    private struct Session {
        var videoCapturer: RTCVideoCapturer
        var videoCapturerDelegate: RTCVideoCapturerDelegate
    }

    init(recorder: RPScreenRecorder = .shared()) {
        self.recorder = recorder
        super.init()
        recorder.delegate = self
    }

    // MARK: - RPScreenRecorderDelegate

    func screenRecorderDidChangeAvailability(_ screenRecorder: RPScreenRecorder) {
        log.debug(
            "\(type(of: self)) availability changed to isAvailable:\(screenRecorder.isAvailable).",
            subsystems: .videoCapturer
        )
    }

    func screenRecorder(
        _ screenRecorder: RPScreenRecorder,
        didStopRecordingWith previewViewController: RPPreviewViewController?,
        error: (any Error)?
    ) {
        if let error {
            log.error(error, subsystems: .videoCapturer)
            Task { [weak self] in
                do {
                    try await self?.stop()
                } catch {
                    log.error(error, subsystems: .videoCapturer)
                }
            }
        }
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
            try await stop()
        default:
            break
        }
    }

    // MARK: Private

    private func execute(
        videoCapturer: RTCVideoCapturer,
        videoCapturerDelegate: RTCVideoCapturerDelegate
    ) async throws {

        guard recorder.isAvailable else {
            throw ClientError("\(type(of: self)) isn't available for recording.")
        }

        guard !isRecording else {
            return
        }

        // We disable the microphone as we don't support .screenShareAudio tracks
        recorder.isMicrophoneEnabled = false
        recorder.isCameraEnabled = false

        try await recorder.startCapture { [weak self] sampleBuffer, sampleBufferType, error in
            if let error {
                log.error(error, subsystems: .videoCapturer)
            } else {
                self?.didReceive(
                    sampleBuffer: sampleBuffer,
                    sampleBufferType: sampleBufferType,
                    error: error
                )
            }
        }

        activeSession = .init(
            videoCapturer: videoCapturer,
            videoCapturerDelegate: videoCapturerDelegate
        )

        isRecording = true

        log.debug(
            "\(type(of: self)) started capturing.",
            subsystems: .videoCapturer
        )
    }

    private func didReceive(
        sampleBuffer: CMSampleBuffer,
        sampleBufferType: RPSampleBufferType,
        error: Error?
    ) {
        guard
            let activeSession
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

    private func stop() async throws {
        guard
            isRecording == true
        else {
            return
        }

        try await recorder.stopCapture()
        activeSession = nil
        isRecording = false
    }
}

extension RPScreenRecorder {

    fileprivate func stopCapture() async throws {
        try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self else {
                continuation.resume(throwing: ClientError())
                return
            }
            stopCapture { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        } as Void
    }
}
