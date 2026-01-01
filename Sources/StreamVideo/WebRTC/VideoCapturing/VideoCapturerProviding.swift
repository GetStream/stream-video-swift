//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamWebRTC

/// A protocol defining methods for creating video capturing objects.
///
/// `VideoCapturerProviding` enables the creation of video capturers for camera
/// and screen sharing. Implementations can define how capturers are configured
/// and initialized, supporting custom sources and optional filters.
protocol VideoCapturerProviding {

    /// Builds a camera capturer with the specified source.
    ///
    /// - Parameters:
    ///   - source: The video source for the capturer, responsible for
    ///     providing captured frames.
    ///   - audioDeviceModule: The audio device module used by the capturer.
    /// - Returns: An instance of `StreamVideoCapturer` for managing camera-based
    ///   video capturing.
    ///
    /// This method is used for creating a video capturer for a camera input,
    /// which can be further configured to process video frames.
    func buildCameraCapturer(
        source: RTCVideoSource,
        audioDeviceModule: AudioDeviceModule
    ) -> StreamVideoCapturing

    /// Builds a screen capturer based on the specified type and source.
    ///
    /// - Parameters:
    ///   - type: The type of screen sharing (`.inApp` or `.broadcast`).
    ///   - source: The video source for the capturer, providing the captured
    ///     frames.
    ///   - audioDeviceModule: The audio device module used by the capturer.
    ///   - includeAudio: Whether to capture app audio during screen sharing.
    ///     Only valid for `.inApp`; ignored otherwise.
    /// - Returns: An instance of `StreamVideoCapturer` for managing screen sharing.
    ///
    /// Depending on the screen sharing type, this method creates a capturer that
    /// supports either in-app screen sharing or broadcasting functionality.
    func buildScreenCapturer(
        _ type: ScreensharingType,
        source: RTCVideoSource,
        audioDeviceModule: AudioDeviceModule,
        includeAudio: Bool
    ) -> StreamVideoCapturing
}

/// A concrete implementation of `VideoCapturerProviding` for creating video capturers.
///
/// `StreamVideoCapturerFactory` provides capturers for both camera and screen sharing
/// scenarios. It supports flexible configurations and integrates with the WebRTC stack
/// to manage video capturing effectively.
final class StreamVideoCapturerFactory: VideoCapturerProviding {

    /// Creates a camera capturer using the specified video source.
    ///
    /// - Parameters:
    ///   - source: The video source for the capturer, responsible for
    ///     providing captured frames.
    ///   - audioDeviceModule: The audio device module used by the capturer.
    /// - Returns: A `StreamVideoCapturer` instance configured for camera capturing.
    ///
    /// This method initializes a camera capturer, suitable for use in scenarios
    /// where a camera is the video input source.
    func buildCameraCapturer(
        source: RTCVideoSource,
        audioDeviceModule: AudioDeviceModule
    ) -> StreamVideoCapturing {
        StreamVideoCapturer.cameraCapturer(
            with: source,
            audioDeviceModule: audioDeviceModule
        )
    }

    /// Creates a screen capturer based on the provided type and source.
    ///
    /// - Parameters:
    ///   - type: The type of screen sharing (`.inApp` or `.broadcast`).
    ///   - source: The video source for the capturer, providing the captured
    ///     frames.
    ///   - audioDeviceModule: The audio device module used by the capturer.
    ///   - includeAudio: Whether to capture app audio during screen sharing.
    ///     Only valid for `.inApp`; ignored otherwise.
    /// - Returns: A `StreamVideoCapturer` instance configured for screen sharing.
    ///
    /// This method dynamically creates a capturer based on the screen sharing type:
    /// - `.inApp`: Configures a capturer for sharing within the app.
    /// - `.broadcast`: Configures a capturer for system-level broadcast sharing.
    ///
    /// Use this method to support flexible screen sharing needs.
    func buildScreenCapturer(
        _ type: ScreensharingType,
        source: RTCVideoSource,
        audioDeviceModule: AudioDeviceModule,
        includeAudio: Bool
    ) -> StreamVideoCapturing {
        switch type {
        case .inApp:
            return StreamVideoCapturer.screenShareCapturer(
                with: source,
                audioDeviceModule: audioDeviceModule,
                includeAudio: includeAudio
            )
        case .broadcast:
            return StreamVideoCapturer.broadcastCapturer(
                with: source,
                audioDeviceModule: audioDeviceModule
            )
        }
    }
}
