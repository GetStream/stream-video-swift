//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
import StreamWebRTC

/// Configures the capture session prior to starting camera capture.
final class CameraCaptureSessionConfigurationHandler: StreamVideoCapturerActionHandler, @unchecked Sendable {

    func handle(_ action: StreamVideoCapturer.Action) async throws {
        switch action {
        case let .startCapture(_, _, _, _, videoCapturer, _, _),
             let .updateCaptureQuality(_, _, _, videoCapturer, _, _):
            guard let cameraCapturer = videoCapturer as? RTCCameraVideoCapturer else {
                return
            }
            configureIfNeeded(cameraCapturer.captureSession)
        default:
            break
        }
    }

    private func configureIfNeeded(_ captureSession: AVCaptureSession) {
        captureSession.usesApplicationAudioSession = true
        captureSession.sessionPreset = .inputPriority
    }
}
