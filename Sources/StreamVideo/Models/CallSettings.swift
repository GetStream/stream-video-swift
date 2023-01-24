//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Combine

/// Represents the settings for a call.
public final class CallSettings: ObservableObject, Sendable {
    /// Whether the audio is on for the current user.
    public let audioOn: Bool
    /// Whether the video is on for the current user.
    public let videoOn: Bool
    /// Whether the sepaker is on for the current user.
    public let speakerOn: Bool
    /// The camera position for the current user.
    public let cameraPosition: CameraPosition
        
    public init(
        audioOn: Bool = true,
        videoOn: Bool = true,
        speakerOn: Bool = true,
        cameraPosition: CameraPosition = .front
    ) {
        self.audioOn = audioOn
        self.speakerOn = speakerOn
        self.cameraPosition = cameraPosition
        #if targetEnvironment(simulator)
        self.videoOn = false
        #else
        self.videoOn = videoOn
        #endif
    }
    
    var shouldPublish: Bool {
        audioOn || videoOn
    }
    
    func withUpdatedCameraPosition(_ cameraPosition: CameraPosition) -> CallSettings {
        CallSettings(
            audioOn: audioOn,
            videoOn: videoOn,
            speakerOn: speakerOn,
            cameraPosition: cameraPosition
        )
    }
}

/// The camera position.
public enum CameraPosition: Sendable {
    case front
    case back
    
    func next() -> CameraPosition {
        self == .front ? .back : .front
    }
}
