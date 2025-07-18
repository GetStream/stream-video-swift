//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
@testable import StreamVideo
import XCTest

final class OwnCapabilitiesAudioSessionPolicyTests: XCTestCase, @unchecked Sendable {

    private lazy var stubbedAppStateAdapter: MockAppStateAdapter! = .init()
    private lazy var subject: OwnCapabilitiesAudioSessionPolicy! = .init()
    private lazy var currentDeviceType: CurrentDevice.DeviceType! = CurrentDevice.DeviceType.phone
    private lazy var currentDevice: CurrentDevice! = .init { self.currentDeviceType }

    override func setUp() {
        super.setUp()
        AppStateProviderKey.currentValue = stubbedAppStateAdapter
        InjectedValues[\.currentDevice] = currentDevice
        _ = subject
    }

    override func tearDown() {
        subject = nil
        stubbedAppStateAdapter = nil
        currentDevice = nil
        InjectedValues[\.currentDevice] = CurrentDevice.currentValue
        super.tearDown()
    }

    // MARK: - Tests for users without sendAudio capability

    func testConfiguration_WhenUserCannotSendAudio_ReturnsPlaybackConfiguration() async {
        // Given
        currentDeviceType = .phone
        await fulfilmentInMainActor { self.currentDevice.deviceType == self.currentDeviceType }
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
        currentDeviceType = .phone
        await fulfilmentInMainActor { self.currentDevice.deviceType == self.currentDeviceType }
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
                .allowBluetooth
            ]
        )
        XCTAssertEqual(configuration.overrideOutputAudioPort, AVAudioSession.PortOverride.none)
    }

    func testConfiguration_WhenUserCanSendAudioAndSpeakerOnWithEarpiece_ReturnsPlayAndRecordConfiguration() async {
        // Given
        currentDeviceType = .phone
        await fulfilmentInMainActor { self.currentDevice.deviceType == self.currentDeviceType }
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
        XCTAssertEqual(
            configuration.options,
            [
                .allowBluetooth
            ]
        )
        XCTAssertEqual(configuration.overrideOutputAudioPort, .speaker)
    }

    func testConfiguration_WhenUserCanSendAudioAndSpeakerOnWithoutEarpiece_ReturnsPlaybackAndRecordConfiguration() async {
        // Given
        currentDeviceType = .pad
        await fulfilmentInMainActor { self.currentDevice.deviceType == self.currentDeviceType }
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
        currentDeviceType = .phone
        await fulfilmentInMainActor { self.currentDevice.deviceType == self.currentDeviceType }
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

    func testConfiguration_WhenVideoOnSpeakerOn_ReturnsVideoChatMode() async {
        // Given
        currentDeviceType = .phone
        await fulfilmentInMainActor { self.currentDevice.deviceType == self.currentDeviceType }
        let callSettings = CallSettings(audioOn: true, videoOn: true, speakerOn: true)
        let ownCapabilities: Set<OwnCapability> = [.sendAudio, .sendVideo]

        // When
        let configuration = subject.configuration(
            for: callSettings,
            ownCapabilities: ownCapabilities
        )

        // Then
        XCTAssertEqual(configuration.mode, .videoChat)
    }

    func testConfiguration_WhenVideoOffSpeakerOnBackgroundFalse_ReturnsVoiceChatMode() async {
        // Given
        currentDeviceType = .phone
        await fulfilmentInMainActor { self.currentDevice.deviceType == self.currentDeviceType }
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
                .allowBluetooth,
                .defaultToSpeaker
            ]
        )
    }

    func testConfiguration_WhenVideoOffSpeakerFalseBackgroundFalse_ReturnsVoiceChatMode() async {
        // Given
        currentDeviceType = .phone
        await fulfilmentInMainActor { self.currentDevice.deviceType == self.currentDeviceType }
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
                .allowBluetooth
            ]
        )
    }

    func testConfiguration_WhenVideoOffSpeakerOnBackgroundTrue_ReturnsVoiceChatMode() async {
        // Given
        currentDeviceType = .phone
        await fulfilmentInMainActor { self.currentDevice.deviceType == self.currentDeviceType }
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
                .allowBluetooth
            ]
        )
    }

    func testConfiguration_WhenVideoOffSpeakerFalseBackgroundTrue_ReturnsVoiceChatMode() async {
        // Given
        currentDeviceType = .phone
        await fulfilmentInMainActor { self.currentDevice.deviceType == self.currentDeviceType }
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
                .allowBluetooth
            ]
        )
    }
}
