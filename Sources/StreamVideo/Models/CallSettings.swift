//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// Represents the settings for a call.
public final class CallSettings: ObservableObject, Sendable, Equatable, CustomStringConvertible {
    public static let `default` = CallSettings()

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

    public convenience init(
        _ response: CallSettingsResponse,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        self.init(
            audioOn: response.audio.micDefaultOn,
            videoOn: response.video.cameraDefaultOn,
            speakerOn: response.speakerOnWithSettingsPriority,
            audioOutputOn: true, // We always have audioOutputOn
            cameraPosition: response.video.cameraFacing == .back ? .back : .front,
            file: file,
            function: function,
            line: line
        )
    }

    public init(
        audioOn: Bool = true,
        videoOn: Bool = true,
        speakerOn: Bool = true,
        audioOutputOn: Bool = true,
        cameraPosition: CameraPosition = .front,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        self.audioOn = audioOn
        self.speakerOn = speakerOn
        self.audioOutputOn = audioOutputOn
        self.cameraPosition = cameraPosition
        if Bundle.containsCameraUsageDescription {
            #if targetEnvironment(simulator)
            // If we are running in tests we want to allow any passed in value.
            if NSClassFromString("XCTestCase") != nil {
                self.videoOn = videoOn
            } else {
                self.videoOn = InjectedValues[\.simulatorStreamFile] != nil ? videoOn : false
            }
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

        log.debug(
            "Created \(self)",
            functionName: function,
            fileName: file,
            lineNumber: line
        )
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

    public var description: String {
        "<CallSettings audioOn:\(audioOn) videoOn:\(videoOn) speakerOn:\(speakerOn) audioOutputOn:\(audioOutputOn) cameraPosition:\(cameraPosition)/>"
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

public extension CallSettings {
    func withUpdatedCameraPosition(
        _ cameraPosition: CameraPosition,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) -> CallSettings {
        CallSettings(
            audioOn: audioOn,
            videoOn: videoOn,
            speakerOn: speakerOn,
            audioOutputOn: audioOutputOn,
            cameraPosition: cameraPosition,
            file: file,
            function: function,
            line: line
        )
    }
    
    func withUpdatedAudioState(
        _ audioOn: Bool,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) -> CallSettings {
        CallSettings(
            audioOn: audioOn,
            videoOn: videoOn,
            speakerOn: speakerOn,
            audioOutputOn: audioOutputOn,
            cameraPosition: cameraPosition,
            file: file,
            function: function,
            line: line
        )
    }
    
    func withUpdatedVideoState(
        _ videoOn: Bool,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) -> CallSettings {
        CallSettings(
            audioOn: audioOn,
            videoOn: videoOn,
            speakerOn: speakerOn,
            audioOutputOn: audioOutputOn,
            cameraPosition: cameraPosition,
            file: file,
            function: function,
            line: line
        )
    }
    
    func withUpdatedSpeakerState(
        _ speakerOn: Bool,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) -> CallSettings {
        CallSettings(
            audioOn: audioOn,
            videoOn: videoOn,
            speakerOn: speakerOn,
            audioOutputOn: audioOutputOn,
            cameraPosition: cameraPosition,
            file: file,
            function: function,
            line: line
        )
    }
    
    func withUpdatedAudioOutputState(
        _ audioOutputOn: Bool,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) -> CallSettings {
        CallSettings(
            audioOn: audioOn,
            videoOn: videoOn,
            speakerOn: speakerOn,
            audioOutputOn: audioOutputOn,
            cameraPosition: cameraPosition,
            file: file,
            function: function,
            line: line
        )
    }
}
