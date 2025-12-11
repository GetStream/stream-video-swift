//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
@testable import StreamVideo
import XCTest

final class OwnCapabilitiesAudioSessionPolicyTests: XCTestCase, @unchecked Sendable {

    private lazy var stubbedAppStateAdapter: MockAppStateAdapter! = .init()
    private lazy var subject: OwnCapabilitiesAudioSessionPolicy! = .init()

    override func setUp() {
        super.setUp()
        AppStateProviderKey.currentValue = stubbedAppStateAdapter
        _ = subject
    }

    override func tearDown() {
        subject = nil
        stubbedAppStateAdapter = nil
        super.tearDown()
    }

    // MARK: - Tests for users without sendAudio capability

    func testConfiguration_WhenUserCannotSendAudio_ReturnsPlaybackConfiguration() async {
        // Given
        CurrentDevice.currentValue.didUpdate(.phone)
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

    func testConfiguration_WhenUserCanSendAudioAndAudioOn_ReturnsPlayAndRecordConfiguration() async {
        // Given
        CurrentDevice.currentValue.didUpdate(.phone)
        let callSettings = CallSettings(audioOn: true, videoOn: true, speakerOn: false)
        let ownCapabilities: Set<OwnCapability> = [.sendAudio, .sendVideo]

        // When
        let configuration = subject.configuration(
            for: callSettings,
            ownCapabilities: ownCapabilities
        )

        // Then
        XCTAssertEqual(configuration.category, .playAndRecord)
        XCTAssertEqual(configuration.mode, .voiceChat)
        XCTAssertEqual(
            configuration.options,
            [
                .allowBluetoothHFP,
                .allowBluetoothA2DP
            ]
        )
        XCTAssertEqual(configuration.overrideOutputAudioPort, AVAudioSession.PortOverride.none)
    }

    func testConfiguration_WhenUserCanSendAudioAndSpeakerOnWithEarpiece_ReturnsPlayAndRecordConfiguration() async {
        // Given
        CurrentDevice.currentValue.didUpdate(.phone)
        let callSettings = CallSettings(audioOn: false, videoOn: true, speakerOn: true)
        let ownCapabilities: Set<OwnCapability> = [.sendAudio, .sendVideo]

        // When
        let configuration = subject.configuration(
            for: callSettings,
            ownCapabilities: ownCapabilities
        )

        // Then
        XCTAssertEqual(configuration.category, .playAndRecord)
        XCTAssertEqual(configuration.mode, .voiceChat)
        XCTAssertEqual(
            configuration.options,
            [
                .allowBluetoothHFP,
                .allowBluetoothA2DP
            ]
        )
        XCTAssertEqual(configuration.overrideOutputAudioPort, .speaker)
    }

    func testConfiguration_WhenUserCanSendAudioAndSpeakerOnWithoutEarpiece_ReturnsPlaybackAndRecordConfiguration() async {
        // Given
        CurrentDevice.currentValue.didUpdate(.pad)
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

    func testConfiguration_WhenUserCanSendAudioAndAudioOff_ReturnsPlaybackConfiguration() async {
        // Given
        CurrentDevice.currentValue.didUpdate(.phone)
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

    func testConfiguration_WhenVideoOffSpeakerOnBackgroundFalse_ReturnsVoiceChatMode() async {
        // Given
        CurrentDevice.currentValue.didUpdate(.phone)
        let callSettings = CallSettings(audioOn: true, videoOn: false, speakerOn: true)
        let ownCapabilities: Set<OwnCapability> = [.sendAudio, .sendVideo]

        // When
        let configuration = subject.configuration(
            for: callSettings,
            ownCapabilities: ownCapabilities
        )

        // Then
        XCTAssertEqual(configuration.mode, .voiceChat)
        XCTAssertEqual(
            configuration.options,
            [
                .allowBluetoothHFP,
                .allowBluetoothA2DP
            ]
        )
    }

    func testConfiguration_WhenVideoOffSpeakerFalseBackgroundFalse_ReturnsVoiceChatMode() async {
        // Given
        CurrentDevice.currentValue.didUpdate(.phone)
        let callSettings = CallSettings(audioOn: true, videoOn: false, speakerOn: false)
        let ownCapabilities: Set<OwnCapability> = [.sendAudio, .sendVideo]

        // When
        let configuration = subject.configuration(
            for: callSettings,
            ownCapabilities: ownCapabilities
        )

        // Then
        XCTAssertEqual(configuration.mode, .voiceChat)
        XCTAssertEqual(
            configuration.options,
            [
                .allowBluetoothHFP,
                .allowBluetoothA2DP
            ]
        )
    }

    func testConfiguration_WhenVideoOffSpeakerOnBackgroundTrue_ReturnsVoiceChatMode() async {
        // Given
        CurrentDevice.currentValue.didUpdate(.phone)
        stubbedAppStateAdapter.stubbedState = .background
        let callSettings = CallSettings(audioOn: true, videoOn: false, speakerOn: true)
        let ownCapabilities: Set<OwnCapability> = [.sendAudio, .sendVideo]

        // When
        let configuration = subject.configuration(
            for: callSettings,
            ownCapabilities: ownCapabilities
        )

        // Then
        XCTAssertEqual(configuration.mode, .voiceChat)
        XCTAssertEqual(
            configuration.options,
            [
                .allowBluetoothHFP,
                .allowBluetoothA2DP
            ]
        )
    }

    func testConfiguration_WhenVideoOffSpeakerFalseBackgroundTrue_ReturnsVoiceChatMode() async {
        // Given
        CurrentDevice.currentValue.didUpdate(.phone)
        stubbedAppStateAdapter.stubbedState = .background
        let callSettings = CallSettings(audioOn: true, videoOn: false, speakerOn: false)
        let ownCapabilities: Set<OwnCapability> = [.sendAudio, .sendVideo]

        // When
        let configuration = subject.configuration(
            for: callSettings,
            ownCapabilities: ownCapabilities
        )

        // Then
        XCTAssertEqual(configuration.mode, .voiceChat)
        XCTAssertEqual(
            configuration.options,
            [
                .allowBluetoothHFP,
                .allowBluetoothA2DP
            ]
        )
    }
}
