//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// Configuration for video capturing settings.
///
/// This structure encapsulates the desired position, dimensions, and frame rate
/// for video capturing. It is used to initialize or update video capture sessions.
struct VideoCapturingConfiguration: Equatable {
    /// The camera position to use for capturing (e.g., front or back camera).
    var position: AVCaptureDevice.Position
    /// The dimensions (width and height) for the captured video.
    var dimensions: CGSize
    /// The frame rate for video capturing in frames per second (fps).
    var frameRate: Int
}

/// Protocol defining the behavior of a video capturing system.
///
/// This protocol outlines the essential operations for starting and stopping
/// video capture sessions. It is intended to be implemented by classes that
/// manage video capturing devices.
protocol VideoCapturing {
    /// Starts capturing video with the specified configuration.
    ///
    /// - Parameter configuration: The desired capturing configuration.
    /// - Throws: An error if the capture session fails to start.
    func startCapture(with configuration: VideoCapturingConfiguration) async throws

    /// Stops the video capturing session.
    ///
    /// - Throws: An error if the capture session fails to stop.
    func stopCapture() async throws
}

/// Protocol extending `VideoCapturing` to add camera-specific functionality.
///
/// This protocol provides additional methods for managing camera settings,
/// such as switching camera positions, applying video filters, and configuring
/// capture quality.
protocol CameraVideoCapturing: VideoCapturing {
    /// Updates the current camera position (e.g., front or back).
    ///
    /// - Parameter cameraPosition: The desired camera position.
    /// - Throws: An error if the camera position cannot be set.
    func setCameraPosition(_ cameraPosition: AVCaptureDevice.Position) async throws

    /// Applies a video filter to the captured video.
    ///
    /// - Parameter videoFilter: An optional video filter to apply.
    func setVideoFilter(_ videoFilter: VideoFilter?)

    /// Updates the capture quality based on provided video layer configurations.
    ///
    /// - Parameters:
    ///   - codecs: The video layers specifying quality configurations.
    ///   - device: The optional capture device to apply these settings to.
    /// - Throws: An error if the quality cannot be updated.
    func updateCaptureQuality(
        _ codecs: [VideoLayer],
        on device: AVCaptureDevice?
    ) async throws

    /// Retrieves the capture device for a given camera position.
    ///
    /// - Parameter cameraPosition: The desired camera position.
    /// - Returns: The corresponding `AVCaptureDevice`, or `nil` if unavailable.
    func capturingDevice(for cameraPosition: AVCaptureDevice.Position) -> AVCaptureDevice?

    /// Zooms the camera by the specified factor.
    ///
    /// - Parameter factor: The zoom factor to apply.
    /// - Throws: An error if the zoom cannot be applied.
    func zoom(by factor: CGFloat) throws

    /// Adjusts the camera focus to the specified point.
    ///
    /// - Parameter point: The focus point in normalized coordinates (0.0 to 1.0).
    /// - Throws: An error if the focus cannot be adjusted.
    func focus(at point: CGPoint) throws

    /// Adds a video output for capturing video data.
    ///
    /// - Parameter videoOutput: The `AVCaptureVideoDataOutput` to add.
    /// - Throws: An error if the video output cannot be added.
    func addVideoOutput(
        _ videoOutput: AVCaptureVideoDataOutput
    ) throws

    /// Removes a previously added video output.
    ///
    /// - Parameter videoOutput: The `AVCaptureVideoDataOutput` to remove.
    /// - Throws: An error if the video output cannot be removed.
    func removeVideoOutput(
        _ videoOutput: AVCaptureVideoDataOutput
    ) throws

    /// Adds a photo output for capturing still images.
    ///
    /// - Parameter capturePhotoOutput: The `AVCapturePhotoOutput` to add.
    /// - Throws: An error if the photo output cannot be added.
    func addCapturePhotoOutput(
        _ capturePhotoOutput: AVCapturePhotoOutput
    ) throws

    /// Removes a previously added photo output.
    ///
    /// - Parameter capturePhotoOutput: The `AVCapturePhotoOutput` to remove.
    /// - Throws: An error if the photo output cannot be removed.
    func removeCapturePhotoOutput(
        _ capturePhotoOutput: AVCapturePhotoOutput
    ) throws
}
