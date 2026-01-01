//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
@testable import StreamVideo
import XCTest

final class DefaultAudioSessionPolicyTests: XCTestCase, @unchecked Sendable {

    private lazy var stubbedAppStateAdapter: MockAppStateAdapter! = .init()
    private lazy var subject: DefaultAudioSessionPolicy! = .init()

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
    
    // MARK: - VideoCall

    func testConfiguration_WhenVideoCallWithSpeakerBackgroundFalse_ReturnsCorrectConfiguration() {
        let callSettings = CallSettings(videoOn: true, speakerOn: true)
        let ownCapabilities: Set<OwnCapability> = [.sendAudio, .sendVideo]

        let configuration = subject.configuration(
            for: callSettings,
            ownCapabilities: ownCapabilities
        )

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

    func testConfiguration_WhenVideoCallWithSpeakerBackgroundTrue_ReturnsCorrectConfiguration() {
        stubbedAppStateAdapter.stubbedState = .background
        let callSettings = CallSettings(videoOn: true, speakerOn: true)
        let ownCapabilities: Set<OwnCapability> = [.sendAudio, .sendVideo]

        let configuration = subject.configuration(
            for: callSettings,
            ownCapabilities: ownCapabilities
        )

        XCTAssertEqual(configuration.category, .playAndRecord)
        XCTAssertEqual(configuration.mode, .voiceChat)
        XCTAssertEqual(
            configuration.options,
            [
                .allowBluetoothHFP,
                .allowBluetoothA2DP
            ]
        )
        XCTAssertNotNil(configuration.overrideOutputAudioPort)
    }

    func testConfiguration_WhenVideoCallWithoutSpeakerBackgroundFalse_ReturnsCorrectConfiguration() {
        let callSettings = CallSettings(videoOn: true, speakerOn: false)
        let ownCapabilities: Set<OwnCapability> = [.sendAudio, .sendVideo]

        let configuration = subject.configuration(
            for: callSettings,
            ownCapabilities: ownCapabilities
        )

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

    func testConfiguration_WhenVideoCallWithoutSpeakerBackgroundTrue_ReturnsCorrectConfiguration() {
        stubbedAppStateAdapter.stubbedState = .background
        let callSettings = CallSettings(videoOn: true, speakerOn: false)
        let ownCapabilities: Set<OwnCapability> = [.sendAudio, .sendVideo]

        let configuration = subject.configuration(
            for: callSettings,
            ownCapabilities: ownCapabilities
        )

        XCTAssertEqual(configuration.category, .playAndRecord)
        XCTAssertEqual(configuration.mode, .voiceChat)
        XCTAssertEqual(
            configuration.options,
            [
                .allowBluetoothHFP,
                .allowBluetoothA2DP
            ]
        )
        XCTAssertNotNil(configuration.overrideOutputAudioPort)
    }

    // MARK: - AudioCall

    func testConfiguration_WhenAudioCallWithSpeakerBackgroundFalse_ReturnsCorrectConfiguration() {
        let callSettings = CallSettings(videoOn: false, speakerOn: true)
        let ownCapabilities: Set<OwnCapability> = [.sendAudio]

        let configuration = subject.configuration(
            for: callSettings,
            ownCapabilities: ownCapabilities
        )

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

    func testConfiguration_WhenAudioCallWithSpeakerBackgroundTrue_ReturnsCorrectConfiguration() {
        stubbedAppStateAdapter.stubbedState = .background
        let callSettings = CallSettings(videoOn: false, speakerOn: true)
        let ownCapabilities: Set<OwnCapability> = [.sendAudio]

        let configuration = subject.configuration(
            for: callSettings,
            ownCapabilities: ownCapabilities
        )

        XCTAssertEqual(configuration.category, .playAndRecord)
        XCTAssertEqual(configuration.mode, .voiceChat)
        XCTAssertEqual(
            configuration.options,
            [
                .allowBluetoothHFP,
                .allowBluetoothA2DP
            ]
        )
        XCTAssertNotNil(configuration.overrideOutputAudioPort)
    }

    func testConfiguration_WhenAudioCallWithoutSpeakerBackgroundFalse_ReturnsCorrectConfiguration() {
        // Δεδομένα
        let callSettings = CallSettings(videoOn: false, speakerOn: false)
        let ownCapabilities: Set<OwnCapability> = [.sendAudio]

        let configuration = subject.configuration(
            for: callSettings,
            ownCapabilities: ownCapabilities
        )
        
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

    func testConfiguration_WhenAudioCallWithoutSpeakerBackgroundTrue_ReturnsCorrectConfiguration() {
        stubbedAppStateAdapter.stubbedState = .background
        let callSettings = CallSettings(videoOn: false, speakerOn: false)
        let ownCapabilities: Set<OwnCapability> = [.sendAudio]

        let configuration = subject.configuration(
            for: callSettings,
            ownCapabilities: ownCapabilities
        )

        XCTAssertEqual(configuration.category, .playAndRecord)
        XCTAssertEqual(configuration.mode, .voiceChat)
        XCTAssertEqual(
            configuration.options,
            [
                .allowBluetoothHFP,
                .allowBluetoothA2DP
            ]
        )
        XCTAssertNotNil(configuration.overrideOutputAudioPort)
    }
}
