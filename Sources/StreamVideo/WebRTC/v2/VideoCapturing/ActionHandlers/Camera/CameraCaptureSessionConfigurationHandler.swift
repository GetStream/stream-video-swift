//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
import StreamWebRTC

/// Configures the camera capture session before capture begins.
///
/// This handler ensures the session is set up for the Stream capture pipeline
/// by applying stable defaults whenever capture starts or quality updates are
/// requested. It is intentionally lightweight and idempotent so it can be
/// called multiple times without side effects.
final class CameraCaptureSessionConfigurationHandler: StreamVideoCapturerActionHandler, @unchecked Sendable {

    /// Applies configuration when capture starts or when capture quality is
    /// updated for the active camera capturer.
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
