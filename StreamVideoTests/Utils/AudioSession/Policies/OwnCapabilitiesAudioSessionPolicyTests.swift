//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
@testable import StreamVideo
import XCTest

final class OwnCapabilitiesAudioSessionPolicyTests: XCTestCase, @unchecked Sendable {

    private var subject: OwnCapabilitiesAudioSessionPolicy! = .init()
    private var currentDevice: CurrentDevice! = .currentValue
    
    override func tearDown() {
        subject = nil
        currentDevice = nil
        super.tearDown()
    }
    
    // MARK: - Tests for users without sendAudio capability
    
    func testConfiguration_WhenUserCannotSendAudio_ReturnsPlaybackConfiguration() {
        // Given
        let callSettings = CallSettings(audioOn: true, videoOn: true, speakerOn: true)
        let ownCapabilities: Set<OwnCapability> = [.sendVideo]
        
        // When
        let configuration = subject.configuration(
            for: callSettings,
            ownCapabilities: ownCapabilities
        )
        
        // Then
        XCTAssertEqual(configuration.category, .playback)
        XCTAssertEqual(configuration.mode, .default)
        XCTAssertEqual(configuration.options, .playback)
        XCTAssertNil(configuration.overrideOutputAudioPort)
    }
    
    // MARK: - Tests for users with sendAudio capability
    
    func testConfiguration_WhenUserCanSendAudioAndAudioOn_ReturnsPlayAndRecordConfiguration() {
        // Given
        let callSettings = CallSettings(audioOn: true, videoOn: true, speakerOn: false)
        let ownCapabilities: Set<OwnCapability> = [.sendAudio, .sendVideo]
        
        // When
        let configuration = subject.configuration(
            for: callSettings,
            ownCapabilities: ownCapabilities
        )
        
        // Then
        XCTAssertEqual(configuration.category, .playAndRecord)
        XCTAssertEqual(configuration.mode, .videoChat)
        XCTAssertEqual(configuration.options, .playAndRecord)
        XCTAssertEqual(configuration.overrideOutputAudioPort, AVAudioSession.PortOverride.none)
    }
    
    func testConfiguration_WhenUserCanSendAudioAndSpeakerOnWithEarpiece_ReturnsPlayAndRecordConfiguration() {
        // Given
        currentDevice.deviceType = .phone
        let callSettings = CallSettings(audioOn: false, videoOn: true, speakerOn: true)
        let ownCapabilities: Set<OwnCapability> = [.sendAudio, .sendVideo]
        
        // When
        let configuration = subject.configuration(
            for: callSettings,
            ownCapabilities: ownCapabilities
        )
        
        // Then
        XCTAssertEqual(configuration.category, .playAndRecord)
        XCTAssertEqual(configuration.mode, .videoChat)
        XCTAssertEqual(configuration.options, .playAndRecord)
        XCTAssertEqual(configuration.overrideOutputAudioPort, .speaker)
    }
    
    func testConfiguration_WhenUserCanSendAudioAndSpeakerOnWithoutEarpiece_ReturnsPlaybackConfiguration() {
        // Given
        currentDevice.deviceType = .pad
        let callSettings = CallSettings(audioOn: false, videoOn: true, speakerOn: true)
        let ownCapabilities: Set<OwnCapability> = [.sendAudio, .sendVideo]
        
        // When
        let configuration = subject.configuration(
            for: callSettings,
            ownCapabilities: ownCapabilities
        )
        
        // Then
        XCTAssertEqual(configuration.category, .playback)
        XCTAssertEqual(configuration.mode, .default)
        XCTAssertEqual(configuration.options, .playback)
        XCTAssertNil(configuration.overrideOutputAudioPort)
    }
    
    func testConfiguration_WhenUserCanSendAudioAndAudioOff_ReturnsPlaybackConfiguration() {
        // Given
        let callSettings = CallSettings(audioOn: false, videoOn: true, speakerOn: false)
        let ownCapabilities: Set<OwnCapability> = [.sendAudio, .sendVideo]
        
        // When
        let configuration = subject.configuration(
            for: callSettings,
            ownCapabilities: ownCapabilities
        )
        
        // Then
        XCTAssertEqual(configuration.category, .playback)
        XCTAssertEqual(configuration.mode, .default)
        XCTAssertEqual(configuration.options, .playback)
        XCTAssertNil(configuration.overrideOutputAudioPort)
    }
    
    // MARK: - Tests for different video settings
    
    func testConfiguration_WhenVideoOn_ReturnsVideoChatMode() {
        // Given
        let callSettings = CallSettings(audioOn: true, videoOn: true, speakerOn: false)
        let ownCapabilities: Set<OwnCapability> = [.sendAudio, .sendVideo]
        
        // When
        let configuration = subject.configuration(
            for: callSettings,
            ownCapabilities: ownCapabilities
        )
        
        // Then
        XCTAssertEqual(configuration.mode, .videoChat)
    }
    
    func testConfiguration_WhenVideoOff_ReturnsVoiceChatMode() {
        // Given
        let callSettings = CallSettings(audioOn: true, videoOn: false, speakerOn: false)
        let ownCapabilities: Set<OwnCapability> = [.sendAudio, .sendVideo]
        
        // When
        let configuration = subject.configuration(
            for: callSettings,
            ownCapabilities: ownCapabilities
        )
        
        // Then
        XCTAssertEqual(configuration.mode, .voiceChat)
    }
}
