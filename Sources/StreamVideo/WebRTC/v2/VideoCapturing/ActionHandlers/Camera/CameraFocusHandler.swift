//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import CoreMedia
import Foundation
import StreamWebRTC

final class CameraFocusHandler: StreamVideoCapturerActionHandler, @unchecked Sendable {

    // MARK: - StreamVideoCapturerActionHandler

    func handle(_ action: StreamVideoCapturer.Action) async throws {
        switch action {
        case let .focus(point, captureSession):
            try execute(
                point: point,
                captureSession: captureSession
            )
        default:
            break
        }
    }

    // MARK: - Private

    /// Initiates a focus and exposure operation at the specified point on the camera's view.
    ///
    /// This method attempts to focus the camera and set the exposure at a specific point by interacting
    /// with the device's capture session.
    /// It requires the `videoCapturer` property to be cast to `RTCCameraVideoCapturer`, and for
    /// a valid `AVCaptureDeviceInput` to be accessible.
    /// If these conditions are not met, it throws a `ClientError` error.
    ///
    /// - Parameter point: A `CGPoint` representing the location within the view where the camera
    /// should adjust focus and exposure.
    /// - Throws: A `ClientError` error if the necessary video capture components are
    /// not available or properly configured.
    ///
    /// - Note: Ensure that the `point` is normalized to the camera's coordinate space, ranging
    /// from (0,0) at the top-left to (1,1) at the bottom-right.
    private func execute(
        point: CGPoint,
        captureSession: AVCaptureSession
    ) throws {
        guard
            let activeCaptureDevice = captureSession.activeVideoCaptureDevice
        else {
            throw ClientError("\(type(of: self)) was unable to perform action because no capturing device found.")
        }

        try activeCaptureDevice.lockForConfiguration()

        if activeCaptureDevice.isFocusPointOfInterestSupported {
            activeCaptureDevice.focusPointOfInterest = point
        } else {
            log.warning(
                "\(type(of: self)) capture device doesn't support focusPointOfInterest.",
                subsystems: .videoCapturer
            )
        }

        if activeCaptureDevice.isFocusModeSupported(.autoFocus) {
            activeCaptureDevice.focusMode = .autoFocus
        } else {
            log.warning(
                "\(type(of: self)) capture device doesn't support focusMode:.autoFocus.",
                subsystems: .videoCapturer
            )
        }

        if activeCaptureDevice.isExposurePointOfInterestSupported {
            activeCaptureDevice.exposurePointOfInterest = point
        } else {
            log.warning(
                "\(type(of: self)) capture device doesn't support exposurePointOfInterest.",
                subsystems: .videoCapturer
            )
        }

        if activeCaptureDevice.isExposureModeSupported(.autoExpose) {
            activeCaptureDevice.exposureMode = .autoExpose
        } else {
            log.warning(
                "\(type(of: self)) capture device doesn't support exposureMode:.autoExpose.",
                subsystems: .videoCapturer
            )
        }

        activeCaptureDevice.unlockForConfiguration()
    }
}
