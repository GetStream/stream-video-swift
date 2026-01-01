//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import CoreMedia
import Foundation
import StreamWebRTC

final class CameraCapturePhotoHandler: StreamVideoCapturerActionHandler, @unchecked Sendable {

    // MARK: - StreamVideoCapturerActionHandler

    func handle(_ action: StreamVideoCapturer.Action) async throws {
        switch action {
        case let .addCapturePhotoOutput(capturePhotoOutput, captureSession):
            try addCapturePhotoOutput(
                capturePhotoOutput: capturePhotoOutput,
                captureSession: captureSession
            )

        case let .removeCapturePhotoOutput(capturePhotoOutput, captureSession):
            removeCapturePhotoOutput(
                capturePhotoOutput: capturePhotoOutput,
                captureSession: captureSession
            )
        default:
            break
        }
    }

    // MARK: - Private

    /// Adds the `AVCapturePhotoOutput` on the `CameraVideoCapturer` to enable photo
    /// capturing capabilities.
    ///
    /// This method configures the local user's `CameraVideoCapturer` with an
    /// `AVCapturePhotoOutput` for capturing photos. This enhancement allows applications to capture
    /// still images while video capturing is ongoing.
    ///
    /// - Parameter capturePhotoOutput: The `AVCapturePhotoOutput` instance to be added
    /// to the `CameraVideoCapturer`. This output enables the capture of photos alongside video
    /// capturing.
    ///
    /// - Throws: An error if the `CameraVideoCapturer` does not support adding an `AVCapturePhotoOutput`.
    /// This method is specifically designed for `RTCCameraVideoCapturer` instances. If the
    /// `CameraVideoCapturer` in use does not support photo output functionality, an appropriate error
    /// will be thrown to indicate that the operation is not supported.
    ///
    /// - Warning: A maximum of one output of each type may be added.
    private func addCapturePhotoOutput(
        capturePhotoOutput: AVCapturePhotoOutput,
        captureSession: AVCaptureSession
    ) throws {
        guard
            captureSession.canAddOutput(capturePhotoOutput)
        else {
            throw ClientError("\(type(of: self)) captureSession cannot addOutput output:\(capturePhotoOutput).")
        }

        captureSession.beginConfiguration()
        captureSession.addOutput(capturePhotoOutput)
        captureSession.commitConfiguration()
    }

    /// Removes the `AVCapturePhotoOutput` from the `CameraVideoCapturer` to disable photo
    /// capturing capabilities.
    ///
    /// This method configures the local user's `CameraVideoCapturer` by removing an
    /// `AVCapturePhotoOutput` previously added for capturing photos. This action is necessary when
    /// the application needs to stop capturing still images or when adjusting the capturing setup. It ensures
    /// that the video capturing process can continue without the overhead or interference of photo
    /// capturing capabilities.
    ///
    /// - Parameter capturePhotoOutput: The `AVCapturePhotoOutput` instance to be removed
    /// from the `CameraVideoCapturer`. Removing this output disables the capture of photos alongside
    /// video capturing.
    ///
    /// - Throws: An error if the `CameraVideoCapturer` does not support removing an
    /// `AVCapturePhotoOutput`.
    /// This method is specifically designed for `RTCCameraVideoCapturer` instances. If the
    /// `CameraVideoCapturer` in use does not support the removal of photo output functionality, an
    /// appropriate error will be thrown to indicate that the operation is not supported.
    ///
    /// - Note: Ensure that the `AVCapturePhotoOutput` being removed was previously added to the
    /// `CameraVideoCapturer`. Attempting to remove an output that is not currently added will not
    /// affect the capture session but may result in unnecessary processing.
    private func removeCapturePhotoOutput(
        capturePhotoOutput: AVCapturePhotoOutput,
        captureSession: AVCaptureSession
    ) {
        captureSession.beginConfiguration()
        captureSession.removeOutput(capturePhotoOutput)
        captureSession.commitConfiguration()
    }
}
