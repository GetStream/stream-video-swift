//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// Represents the settings for a call.
public final class CallSettings: ObservableObject, Sendable, Equatable, ReflectiveStringConvertible {
    /// Whether the audio is on for the current user.
    public let audioOn: Bool
    /// Whether the video is on for the current user.
    public let videoOn: Bool
    /// Whether the speaker is on for the current user.
    public let speakerOn: Bool
    /// Whether the audio output is on for the current user.
    public let audioOutputOn: Bool
    /// The camera position for the current user.
    public let cameraPosition: CameraPosition
    
    public init(
        audioOn: Bool = true,
        videoOn: Bool = true,
        speakerOn: Bool = true,
        audioOutputOn: Bool = true,
        cameraPosition: CameraPosition = .front
    ) {
        self.audioOn = audioOn
        self.speakerOn = speakerOn
        self.audioOutputOn = audioOutputOn
        self.cameraPosition = cameraPosition
        if Bundle.containsCameraUsageDescription {
            #if targetEnvironment(simulator)
            self.videoOn = InjectedValues[\.simulatorStreamFile] != nil ? videoOn : false
            #else
            self.videoOn = videoOn
            #endif
        } else {
            if videoOn {
                log
                    .warning(
                        "Stream's dashboard configuration includes video capturing but the application doesn't provide a camera usage description. Video will not be available in order to prevent the app crashing. Please make sure to add the camera usage description as described in Apple's documentation https://developer.apple.com/documentation/BundleResources/Information-Property-List/NSCameraUsageDescription"
                    )
            }
            self.videoOn = false
        }
    }
    
    public static func == (lhs: CallSettings, rhs: CallSettings) -> Bool {
        lhs.audioOn == rhs.audioOn &&
            lhs.videoOn == rhs.videoOn &&
            lhs.speakerOn == rhs.speakerOn &&
            lhs.audioOutputOn == rhs.audioOutputOn &&
            lhs.cameraPosition == rhs.cameraPosition
    }
    
    public var shouldPublish: Bool {
        audioOn || videoOn
    }
}

/// The camera position.
public enum CameraPosition: Sendable, Equatable {
    case front
    case back
    
    public func next() -> CameraPosition {
        self == .front ? .back : .front
    }
}

extension CallSettingsResponse {
    
    public var toCallSettings: CallSettings {
        CallSettings(
            audioOn: audio.micDefaultOn,
            videoOn: video.cameraDefaultOn,
            speakerOn: video.cameraDefaultOn ? true : audio.defaultDevice == .speaker,
            audioOutputOn: audio.speakerDefaultOn,
            cameraPosition: video.cameraFacing == .back ? .back : .front
        )
    }
}

public extension CallSettings {
    func withUpdatedCameraPosition(_ cameraPosition: CameraPosition) -> CallSettings {
        CallSettings(
            audioOn: audioOn,
            videoOn: videoOn,
            speakerOn: speakerOn,
            audioOutputOn: audioOutputOn,
            cameraPosition: cameraPosition
        )
    }
    
    func withUpdatedAudioState(_ audioOn: Bool) -> CallSettings {
        CallSettings(
            audioOn: audioOn,
            videoOn: videoOn,
            speakerOn: speakerOn,
            audioOutputOn: audioOutputOn,
            cameraPosition: cameraPosition
        )
    }
    
    func withUpdatedVideoState(_ videoOn: Bool) -> CallSettings {
        CallSettings(
            audioOn: audioOn,
            videoOn: videoOn,
            speakerOn: speakerOn,
            audioOutputOn: audioOutputOn,
            cameraPosition: cameraPosition
        )
    }
    
    func withUpdatedSpeakerState(_ speakerOn: Bool) -> CallSettings {
        CallSettings(
            audioOn: audioOn,
            videoOn: videoOn,
            speakerOn: speakerOn,
            audioOutputOn: audioOutputOn,
            cameraPosition: cameraPosition
        )
    }
    
    func withUpdatedAudioOutputState(_ audioOutputOn: Bool) -> CallSettings {
        CallSettings(
            audioOn: audioOn,
            videoOn: videoOn,
            speakerOn: speakerOn,
            audioOutputOn: audioOutputOn,
            cameraPosition: cameraPosition
        )
    }
}
