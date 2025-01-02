//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamWebRTC

/// A protocol defining methods for creating video capturing objects.
protocol VideoCapturerProviding {

    /// Builds a camera capturer with the specified source, options, and filters.
    /// - Parameters:
    ///   - source: The video source for the capturer.
    ///   - options: Configuration options for the video capture.
    ///   - filters: An array of video filters to apply.
    /// - Returns: An object conforming to `CameraVideoCapturing` for camera capture.
    func buildCameraCapturer(
        source: RTCVideoSource,
        options: VideoOptions,
        filters: [VideoFilter]
    ) -> CameraVideoCapturing

    /// Builds a screen capturer with the specified type, source, options, and filters.
    /// - Parameters:
    ///   - type: The type of screen sharing to perform.
    ///   - source: The video source for the capturer.
    ///   - options: Configuration options for the video capture.
    ///   - filters: An array of video filters to apply.
    /// - Returns: An object conforming to `VideoCapturing` for screen capture.
    func buildScreenCapturer(
        _ type: ScreensharingType,
        source: RTCVideoSource,
        options: VideoOptions,
        filters: [VideoFilter]
    ) -> VideoCapturing
}

/// A concrete implementation of `VideoCapturerProviding` for creating video capturers.
final class StreamVideoCapturerFactory: VideoCapturerProviding {

    /// Creates a camera capturer with the given parameters.
    /// - Parameters:
    ///   - source: The video source for the capturer.
    ///   - options: Configuration options for the video capture.
    ///   - filters: An array of video filters to apply.
    /// - Returns: A `VideoCapturer` instance for camera capture.
    func buildCameraCapturer(
        source: RTCVideoSource,
        options: VideoOptions,
        filters: [VideoFilter]
    ) -> CameraVideoCapturing {
        VideoCapturer(
            videoSource: source,
            videoOptions: options,
            videoFilters: filters
        )
    }

    /// Creates a screen capturer based on the specified type and parameters.
    /// - Parameters:
    ///   - type: The type of screen sharing to perform.
    ///   - source: The video source for the capturer.
    ///   - options: Configuration options for the video capture.
    ///   - filters: An array of video filters to apply.
    /// - Returns: A `VideoCapturing` instance for screen capture, either `ScreenshareCapturer` or `BroadcastScreenCapturer`.
    func buildScreenCapturer(
        _ type: ScreensharingType,
        source: RTCVideoSource,
        options: VideoOptions,
        filters: [VideoFilter]
    ) -> VideoCapturing {
        switch type {
        case .inApp:
            return ScreenshareCapturer(
                videoSource: source,
                videoOptions: options,
                videoFilters: filters
            )
        case .broadcast:
            return BroadcastScreenCapturer(
                videoSource: source,
                videoOptions: options,
                videoFilters: filters
            )
        }
    }
}
