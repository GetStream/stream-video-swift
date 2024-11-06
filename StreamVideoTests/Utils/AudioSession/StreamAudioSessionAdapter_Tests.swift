//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import AVFoundation
@testable import StreamVideo
import StreamWebRTC
@preconcurrency import XCTest

final class StreamAudioSessionAdapter_Tests: XCTestCase, @unchecked Sendable {

    private lazy var audioSession: MockAudioSession! = .init()
    private lazy var subject: StreamAudioSessionAdapter! = StreamAudioSessionAdapter(audioSession)

    // MARK: - Lifecycle

    override func tearDown() {
        subject = nil
        audioSession = nil
        super.tearDown()
    }

    // MARK: - init

    func test_init_callAudioSessionKeyCurrentValueUpdated() {
        _ = subject
        XCTAssertTrue(StreamActiveCallAudioSessionKey.currentValue === audioSession)
    }

    func test_init_setsManualAudioAndEnabled() {
        _ = subject

        XCTAssertTrue(audioSession.useManualAudio)
        XCTAssertTrue(audioSession.isAudioEnabled)
    }

    func test_init_updatesConfiguration() async throws {
        let expected = RTCAudioSessionConfiguration.default

        _ = subject
        await fulfillment { self.audioSession.timesCalled(.updateConfiguration) == 1 }

        let actual = try XCTUnwrap(
            audioSession.recordedInputPayload(
                RTCAudioSessionConfiguration.self,
                for: .setConfiguration
            )?.first
        )
        XCTAssertEqual(actual, expected)
    }

    // MARK: - deinit

    func test_deinit_callAudioSessionKeyCurrentValueSetToNil() {
        _ = subject
        XCTAssertTrue(StreamActiveCallAudioSessionKey.currentValue === audioSession)

        subject = nil

        XCTAssertNil(StreamActiveCallAudioSessionKey.currentValue)
    }

    // MARK: - Active Call Settings Tests

    func test_didUpdateCallSettings_withUpdatedCallSettingsAudioOutputOn_updatesAudioSession() async throws {
        let callSettings = CallSettings(audioOn: false, audioOutputOn: true)

        subject.didUpdateCallSettings(callSettings)

        await fulfillment { self.audioSession.timesCalled(.setActive) == 1 }
    }

    func test_didUpdateCallSettings_withUpdatedCallSettingsSpeakerOn_updatesAudioSession() async throws {
        audioSession.category = .unique
        let callSettings = CallSettings(speakerOn: true)

        subject.didUpdateCallSettings(callSettings)

        await fulfillment { self.audioSession.timesCalled(.overrideOutputAudioPort) == 1 }
        XCTAssertEqual(
            audioSession.recordedInputPayload(
                String.self,
                for: .setMode
            )?.first,
            AVAudioSession.Mode.videoChat.rawValue
        )
        XCTAssertEqual(
            audioSession.recordedInputPayload(
                (String, AVAudioSession.CategoryOptions).self,
                for: .setCategory
            )?.first?.0,
            audioSession.category
        )
        XCTAssertEqual(
            audioSession.recordedInputPayload(
                (String, AVAudioSession.CategoryOptions).self,
                for: .setCategory
            )?.first?.1,
            [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP]
        )
        XCTAssertEqual(
            audioSession.recordedInputPayload(
                AVAudioSession.PortOverride.self,
                for: .overrideOutputAudioPort
            )?.first,
            .speaker
        )
    }

    func test_didUpdateCallSettings_withUpdatedCallSettingsSpeakerOf_updatesAudioSession() async throws {
        audioSession.category = .unique
        subject.didUpdateCallSettings(CallSettings(speakerOn: true))
        await fulfillment { self.audioSession.timesCalled(.overrideOutputAudioPort) == 1 }
        audioSession.resetRecords(for: .setMode)
        audioSession.resetRecords(for: .setCategory)
        audioSession.resetRecords(for: .overrideOutputAudioPort)
        audioSession.isUsingSpeakerOutput = true

        subject.didUpdateCallSettings(CallSettings(speakerOn: false))

        await fulfillment { self.audioSession.timesCalled(.overrideOutputAudioPort) == 1 }
        XCTAssertEqual(
            audioSession.recordedInputPayload(
                String.self,
                for: .setMode
            )?.first,
            AVAudioSession.Mode.voiceChat.rawValue
        )
        XCTAssertEqual(
            audioSession.recordedInputPayload(
                (String, AVAudioSession.CategoryOptions).self,
                for: .setCategory
            )?.first?.0,
            audioSession.category
        )
        XCTAssertEqual(
            audioSession.recordedInputPayload(
                (String, AVAudioSession.CategoryOptions).self,
                for: .setCategory
            )?.first?.1,
            [.allowBluetooth, .allowBluetoothA2DP]
        )
        XCTAssertEqual(
            audioSession.recordedInputPayload(
                AVAudioSession.PortOverride.self,
                for: .overrideOutputAudioPort
            )?.first,
            AVAudioSession.PortOverride.none
        )
    }

    func test_didUpdateCallSettings_withoutChanges_doesNotUpdateAudioSession() async throws {
        audioSession.isActive = true
        let callSettings = CallSettings(audioOn: false, videoOn: true)
        subject.didUpdateCallSettings(callSettings)
        await fulfillment { self.audioSession.timesCalled(.updateConfiguration) > 0 }
        audioSession.resetRecords(for: .updateConfiguration)

        subject.didUpdateCallSettings(callSettings)

        XCTAssertEqual(audioSession.timesCalled(.updateConfiguration), 0)
    }

    // MARK: - Audio Session Delegate Tests

    // MARK: routeUpdate

    func test_audioSessionDidChangeRoute_reasonUnkwnown_updatesCallSettingsForNewRoute() async {
        await assertRouteUpdate(
            initialSpeakerOn: true,
            reason: .unknown,
            expectedSpeakerOn: false
        )
    }

    func test_audioSessionDidChangeRoute_reasonNewDeviceAvailable_updatesCallSettingsForNewRoute() async {
        await assertRouteUpdate(
            initialSpeakerOn: true,
            reason: .newDeviceAvailable,
            expectedSpeakerOn: false
        )
    }

    func test_audioSessionDidChangeRoute_reasonOverride_updatesCallSettingsForNewRoute() async {
        await assertRouteUpdate(
            initialSpeakerOn: true,
            reason: .override,
            expectedSpeakerOn: false
        )
    }

    func test_audioSessionDidChangeRoute_reasonNoSuitableRouteForCategory_updatesCallSettingsForNewRoute() async {
        await assertRouteUpdate(
            initialSpeakerOn: true,
            reason: .noSuitableRouteForCategory,
            expectedSpeakerOn: false
        )
    }

    // MARK: respectCallSettings

    func test_audioSessionDidChangeRoute_reasonOldDeviceUnavailable_updatesCallSettingsForNewRoute() async {
        await assertRespectCallSettings(
            callSettingsSpeakerOn: true,
            reason: .oldDeviceUnavailable,
            isUsingSpeakerOutput: false,
            expectedMode: .videoChat,
            expectedCategoryOptions: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP],
            expectedOverrideOutputAudioPort: .speaker
        )
    }

    func test_audioSessionDidChangeRoute_reasonCategoryChange_updatesCallSettingsForNewRoute() async {
        await assertRespectCallSettings(
            callSettingsSpeakerOn: true,
            reason: .categoryChange,
            isUsingSpeakerOutput: false,
            expectedMode: .videoChat,
            expectedCategoryOptions: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP],
            expectedOverrideOutputAudioPort: .speaker
        )
    }

    func test_audioSessionDidChangeRoute_reasonWakeFromSleep_updatesCallSettingsForNewRoute() async {
        await assertRespectCallSettings(
            callSettingsSpeakerOn: true,
            reason: .wakeFromSleep,
            isUsingSpeakerOutput: false,
            expectedMode: .videoChat,
            expectedCategoryOptions: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP],
            expectedOverrideOutputAudioPort: .speaker
        )
    }

    func test_audioSessionDidChangeRoute_reasonRouteConfigurationChange_updatesCallSettingsForNewRoute() async {
        await assertRespectCallSettings(
            callSettingsSpeakerOn: true,
            reason: .routeConfigurationChange,
            isUsingSpeakerOutput: false,
            expectedMode: .videoChat,
            expectedCategoryOptions: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP],
            expectedOverrideOutputAudioPort: .speaker
        )
    }

    // MARK: - Private Helper Tests

    private func assertRouteUpdate(
        initialSpeakerOn: Bool,
        reason: AVAudioSession.RouteChangeReason,
        expectedSpeakerOn: Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        subject.didUpdateCallSettings(.init(speakerOn: initialSpeakerOn))
        audioSession.isUsingSpeakerOutput = expectedSpeakerOn
        let delegate = MockStreamAudioSessionAdapterDelegate()
        subject.delegate = delegate

        subject.audioSessionDidChangeRoute(
            .sharedInstance(),
            reason: reason,
            previousRoute: .init()
        )

        await fulfillment(
            file: file,
            line: line
        ) { delegate.audioSessionAdapterDidUpdateCallSettingsWithCallSettings != nil }
        XCTAssertEqual(
            delegate.audioSessionAdapterDidUpdateCallSettingsWithCallSettings?.speakerOn,
            expectedSpeakerOn,
            file: file,
            line: line
        )
    }

    private func assertRespectCallSettings(
        callSettingsSpeakerOn: Bool,
        reason: AVAudioSession.RouteChangeReason,
        isUsingSpeakerOutput: Bool,
        expectedMode: AVAudioSession.Mode,
        expectedCategoryOptions: AVAudioSession.CategoryOptions,
        expectedOverrideOutputAudioPort: AVAudioSession.PortOverride,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        audioSession.category = .unique
        subject.didUpdateCallSettings(.init(speakerOn: callSettingsSpeakerOn))
        audioSession.isUsingSpeakerOutput = isUsingSpeakerOutput
        let delegate = MockStreamAudioSessionAdapterDelegate()
        subject.delegate = delegate
        audioSession.resetRecords(for: .setMode)
        audioSession.resetRecords(for: .setCategory)
        audioSession.resetRecords(for: .overrideOutputAudioPort)

        subject.audioSessionDidChangeRoute(
            .sharedInstance(),
            reason: reason,
            previousRoute: .init()
        )

        await fulfillment(
            file: file,
            line: line
        ) { self.audioSession.timesCalled(.overrideOutputAudioPort) == 1 }
        XCTAssertEqual(
            audioSession.recordedInputPayload(
                String.self,
                for: .setMode
            )?.first,
            expectedMode.rawValue,
            file: file,
            line: line
        )
        XCTAssertEqual(
            audioSession.recordedInputPayload(
                (String, AVAudioSession.CategoryOptions).self,
                for: .setCategory
            )?.first?.0,
            audioSession.category,
            file: file,
            line: line
        )
        XCTAssertEqual(
            audioSession.recordedInputPayload(
                (String, AVAudioSession.CategoryOptions).self,
                for: .setCategory
            )?.first?.1,
            expectedCategoryOptions,
            file: file,
            line: line
        )
        XCTAssertEqual(
            audioSession.recordedInputPayload(
                AVAudioSession.PortOverride.self,
                for: .overrideOutputAudioPort
            )?.first,
            expectedOverrideOutputAudioPort,
            file: file,
            line: line
        )
    }
}

final class MockStreamAudioSessionAdapterDelegate: StreamAudioSessionAdapterDelegate, @unchecked Sendable {
    private(set) var audioSessionAdapterDidUpdateCallSettingsWithCallSettings: CallSettings?
    func audioSessionAdapterDidUpdateCallSettings(
        _ adapter: StreamAudioSessionAdapter,
        callSettings: CallSettings
    ) {
        audioSessionAdapterDidUpdateCallSettingsWithCallSettings = callSettings
    }
}
