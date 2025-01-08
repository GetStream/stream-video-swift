//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamWebRTC

extension RTCCameraVideoCapturer {
    func startCapture(
        with device: CaptureDeviceProtocol,
        format: AVCaptureDevice.Format,
        fps: Int
    ) async throws {
        guard let avCaptureDevice = device as? AVCaptureDevice else {
            throw ClientError("Unsupported capturing device.")
        }
        try await withCheckedThrowingContinuation { continuation in
            self.startCapture(
                with: avCaptureDevice,
                format: format,
                fps: fps
            ) { error in
                if let error {
                    continuation.resume(throwing: ClientError(error.localizedDescription))
                } else {
                    continuation.resume()
                }
            }
        } as Void
    }
}
