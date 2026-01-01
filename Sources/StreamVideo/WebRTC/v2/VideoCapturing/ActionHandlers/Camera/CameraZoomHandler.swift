//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

final class CameraZoomHandler: StreamVideoCapturerActionHandler, @unchecked Sendable {

    // MARK: - StreamVideoCapturerActionHandler

    func handle(_ action: StreamVideoCapturer.Action) async throws {
        switch action {
        case let .zoom(factor, captureSession):
            try execute(
                factor: factor,
                captureSession: captureSession
            )
        default:
            break
        }
    }

    // MARK: - Private

    /// Zooms the camera video by the specified factor.
    ///
    /// This method attempts to zoom the camera's video feed by adjusting the `videoZoomFactor` of
    /// the camera's active device. It first checks if the video capturer is of type `RTCCameraVideoCapturer`
    /// and if the current camera device supports zoom by verifying that the `videoMaxZoomFactor` of
    /// the active format is greater than 1.0. If these conditions are met, it proceeds to apply the requested
    /// zoom factor, clamping it within the supported range to avoid exceeding the device's capabilities.
    ///
    /// - Parameter factor: The desired zoom factor. A value of 1.0 represents no zoom, while values
    /// greater than 1.0 increase the zoom level. The factor is clamped to the maximum zoom factor supported
    /// by the device to ensure it remains within valid bounds.
    ///
    /// - Throws: `ClientError.Unexpected` if the video capturer is not of type
    /// `RTCCameraVideoCapturer`, or if the device does not support zoom. Also, throws an error if
    /// locking the device for configuration fails.
    ///
    /// - Note: This method should be used cautiously, as setting a zoom factor significantly beyond the
    /// optimal range can degrade video quality.
    private func execute(
        factor: CGFloat,
        captureSession: AVCaptureSession
    ) throws {
        guard
            let activeCaptureDevice = captureSession.activeVideoCaptureDevice,
            activeCaptureDevice.activeFormat.videoMaxZoomFactor > 1.0 // That ensures that the devices supports zoom.
        else {
            throw ClientError("\(type(of: self)) captureDevice doesn't support zoom.")
        }

        try activeCaptureDevice.lockForConfiguration()
        let zoomFactor = max(1.0, min(factor, activeCaptureDevice.activeFormat.videoMaxZoomFactor))
        activeCaptureDevice.videoZoomFactor = zoomFactor
        activeCaptureDevice.unlockForConfiguration()
    }
}
