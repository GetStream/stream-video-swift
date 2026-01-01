//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamWebRTC

/// An extension of `RTCCameraVideoCapturer` to add a convenience method for
/// starting the video capture with a specified device, format, and frame rate.
///
/// - Parameters:
///   - device: The capturing device conforming to `CaptureDeviceProtocol`.
///   - format: The desired `AVCaptureDevice.Format` for the capture.
///   - fps: The desired frame rate for the capture.
/// - Throws: `ClientError` if the device is not supported or if an error
///   occurs during the capture start process.
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
