//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamWebRTC

/// A protocol defining methods for creating video capturing objects.
///
/// `VideoCapturerProviding` allows the creation of capturers for both cameras and
/// screen sharing, with support for configuring options and applying filters.
protocol VideoCapturerProviding {

    /// Builds a camera capturer with the specified source and filters.
    ///
    /// - Parameters:
    ///   - source: The video source for the capturer, providing the captured frames.
    /// - Returns: An object conforming to `CameraVideoCapturing` for managing
    ///   camera capture operations.
    func buildCameraCapturer(
        source: RTCVideoSource
    ) -> StreamVideoCapturer

    /// Builds a screen capturer with the specified type, source, options, and filters.
    ///
    /// - Parameters:
    ///   - type: The type of screen sharing to perform (`.inApp` or `.broadcast`).
    ///   - source: The video source for the capturer, providing the captured frames.
    ///   - options: Configuration options for screen capture (e.g., resolution, bitrate).
    /// - Returns: An object conforming to `VideoCapturing` for managing screen capture.
    func buildScreenCapturer(
        _ type: ScreensharingType,
        source: RTCVideoSource
    ) -> StreamVideoCapturer
}

/// A concrete implementation of `VideoCapturerProviding` for creating video capturers.
///
/// `StreamVideoCapturerFactory` generates video capturers for camera and screen sharing.
/// It supports applying video filters and configuring capture settings for each type.
final class StreamVideoCapturerFactory: VideoCapturerProviding {

    /// Creates a camera capturer with the given parameters.
    ///
    /// - Parameters:
    ///   - source: The video source for the capturer, providing the captured frames.
    /// - Returns: A `CameraVideoCapturing` instance for managing camera capture.
    func buildCameraCapturer(
        source: RTCVideoSource
    ) -> StreamVideoCapturer {
        .cameraCapturer(with: source)
    }

    /// Creates a screen capturer based on the specified type and parameters.
    ///
    /// - Parameters:
    ///   - type: The type of screen sharing to perform (`.inApp` or `.broadcast`).
    ///   - source: The video source for the capturer, providing the captured frames.
    ///   - options: Configuration options for screen capture (e.g., resolution, bitrate).
    /// - Returns: A `VideoCapturing` instance for managing screen capture. Depending
    ///   on the type, it returns either a `ScreenshareCapturer` or `BroadcastScreenCapturer`.
    func buildScreenCapturer(
        _ type: ScreensharingType,
        source: RTCVideoSource
    ) -> StreamVideoCapturer {
        switch type {
        case .inApp:
            return .screenShareCapturer(with: source)
        case .broadcast:
            return .broadcastCapturer(with: source)
        }
    }
}
