//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class CallSettingsResponse_SettingsPriorityTests: XCTestCase, @unchecked Sendable {
    
    func test_speakerOnWithSettingsPriority_whenVideoCameraDefaultOn_returnsTrue() {
        // Given
        let videoSettings = VideoSettings(
            accessRequestEnabled: true,
            cameraDefaultOn: true,
            cameraFacing: .front,
            enabled: true,
            targetResolution: .init(bitrate: 100, height: 100, width: 100)
        )
        
        let audioSettings = AudioSettings(
            accessRequestEnabled: true,
            defaultDevice: .earpiece,
            micDefaultOn: true,
            opusDtxEnabled: true,
            redundantCodingEnabled: true,
            speakerDefaultOn: false
        )
        
        let settings = CallSettingsResponse.dummy(
            audio: audioSettings,
            video: videoSettings
        )
        
        // When
        let result = settings.speakerOnWithSettingsPriority
        
        // Then
        XCTAssertTrue(result)
    }
    
    func test_speakerOnWithSettingsPriority_whenAudioSpeakerDefaultOn_returnsTrue() {
        // Given
        let videoSettings = VideoSettings(
            accessRequestEnabled: true,
            cameraDefaultOn: false,
            cameraFacing: .front,
            enabled: true,
            targetResolution: .init(bitrate: 100, height: 100, width: 100)
        )
        
        let audioSettings = AudioSettings(
            accessRequestEnabled: true,
            defaultDevice: .earpiece,
            micDefaultOn: true,
            opusDtxEnabled: true,
            redundantCodingEnabled: true,
            speakerDefaultOn: true
        )
        
        let settings = CallSettingsResponse.dummy(
            audio: audioSettings,
            video: videoSettings
        )

        // When
        let result = settings.speakerOnWithSettingsPriority
        
        // Then
        XCTAssertTrue(result)
    }
    
    func test_speakerOnWithSettingsPriority_whenDefaultDeviceIsSpeaker_returnsTrue() {
        // Given
        let videoSettings = VideoSettings(
            accessRequestEnabled: true,
            cameraDefaultOn: false,
            cameraFacing: .front,
            enabled: true,
            targetResolution: .init(bitrate: 100, height: 100, width: 100)
        )
        
        let audioSettings = AudioSettings(
            accessRequestEnabled: true,
            defaultDevice: .speaker,
            micDefaultOn: true,
            opusDtxEnabled: true,
            redundantCodingEnabled: true,
            speakerDefaultOn: false
        )
        
        let settings = CallSettingsResponse.dummy(
            audio: audioSettings,
            video: videoSettings
        )
        
        // When
        let result = settings.speakerOnWithSettingsPriority
        
        // Then
        XCTAssertTrue(result)
    }
    
    func test_speakerOnWithSettingsPriority_whenNoConditionsMet_returnsFalse() {
        // Given
        let videoSettings = VideoSettings(
            accessRequestEnabled: true,
            cameraDefaultOn: false,
            cameraFacing: .front,
            enabled: true,
            targetResolution: .init(bitrate: 100, height: 100, width: 100)
        )
        
        let audioSettings = AudioSettings(
            accessRequestEnabled: true,
            defaultDevice: .earpiece,
            micDefaultOn: true,
            opusDtxEnabled: true,
            redundantCodingEnabled: true,
            speakerDefaultOn: false
        )
        
        let settings = CallSettingsResponse.dummy(
            audio: audioSettings,
            video: videoSettings
        )
        
        // When
        let result = settings.speakerOnWithSettingsPriority
        
        // Then
        XCTAssertFalse(result)
    }
}
