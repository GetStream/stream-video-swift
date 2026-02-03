//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// A video capturer provider that uses an external video source (e.g. wearable camera). No device camera is used.
/// When the call enables video, `sessionReadyCallback` is invoked with an `ExternalFrameSink`; push frames at your desired rate (e.g. ~30 fps).
public final class ExternalVideoCapturerProvider: VideoCapturerProviding, Sendable {

    private let sessionReadyCallback: @Sendable (ExternalFrameSink) -> Void

    public init(sessionReadyCallback: @escaping @Sendable (ExternalFrameSink) -> Void) {
        self.sessionReadyCallback = sessionReadyCallback
    }

    func buildCameraCapturer(
        source: RTCVideoSource,
        audioDeviceModule: AudioDeviceModule
    ) -> StreamVideoCapturing {
        StreamVideoCapturer.externalSourceCapturer(
            with: source,
            audioDeviceModule: audioDeviceModule,
            sessionReadyCallback: sessionReadyCallback
        )
    }

    func buildScreenCapturer(
        _ type: ScreensharingType,
        source: RTCVideoSource,
        audioDeviceModule: AudioDeviceModule,
        includeAudio: Bool
    ) -> StreamVideoCapturing {
        StreamVideoCapturer.broadcastCapturer(
            with: source,
            audioDeviceModule: audioDeviceModule
        )
    }
}
