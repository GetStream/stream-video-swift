//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
@testable import StreamVideo
import StreamWebRTC
import XCTest

final class StreamAudioSession_Tests: XCTestCase, @unchecked Sendable {

    private lazy var disposableBag: DisposableBag! = .init()
    private lazy var mockAudioSession: MockAudioSession! = .init()
    private lazy var mockPolicy: MockAudioSessionPolicy! = .init()
    private lazy var subject: StreamAudioSession! = .init(
        policy: mockPolicy,
        audioSession: mockAudioSession
    )

    override func tearDown() {
        subject.dismantle()
        subject = nil
        disposableBag.removeAll()
        mockAudioSession = nil
        mockPolicy = nil
        super.tearDown()
    }

    // MARK: - init

    func test_init_configuresManualAudioAndEnablesAudioByDefault() throws {
        _ = subject

        XCTAssertTrue(mockAudioSession.useManualAudio)
        XCTAssertTrue(mockAudioSession.isAudioEnabled)
    }

    func test_init_currentValueWasSet() {
        _ = subject

        XCTAssertTrue(StreamAudioSession.currentValue === subject)
    }

    // MARK: - didUpdateOwnCapabilities(_:)

    func test_didUpdateOwnCapabilities_policyWasCalled() async throws {
        let ownCapabilities: Set<OwnCapability> = [.createCall]
        try await assertConfigurationWasCalledOnPolicy({
            try await self.subject.didUpdateOwnCapabilities(ownCapabilities)
        }, expectedInput: [(subject.activeCallSettings, ownCapabilities)])
    }

    func test_didUpdateOwnCapabilities_withoutAnyChanges_policyWasCalledTwice() async throws {
        let ownCapabilities: Set<OwnCapability> = [.createCall]
        try await assertConfigurationWasCalledOnPolicy({
            try await self.subject.didUpdateOwnCapabilities(ownCapabilities)
            try await self.subject.didUpdateOwnCapabilities(ownCapabilities)
        }, expectedInput: [
            (subject.activeCallSettings, ownCapabilities),
            (subject.activeCallSettings, ownCapabilities)
        ])
    }

    // MARK: - didUpdateCallSettings(_:)

    func test_didUpdateCallSettings_policyWasCalled() async throws {
        let callSettings = CallSettings(speakerOn: false)
        try await assertConfigurationWasCalledOnPolicy({
            try await self.subject.didUpdateCallSettings(callSettings)
        }, expectedInput: [(callSettings, [])])
    }

    func test_didUpdateCallSettings_withoutAnyChanges_policyWasCalledTwice() async throws {
        let callSettings = CallSettings(speakerOn: false)
        try await assertConfigurationWasCalledOnPolicy({
            try await self.subject.didUpdateCallSettings(callSettings)
            try await self.subject.didUpdateCallSettings(callSettings)
        }, expectedInput: [
            (callSettings, []),
            (callSettings, [])
        ])
    }

    func test_didUpdateCallSettings_policyReturnsNoOverrideOutputPortWithCategoryPlayAndRecord_overrideOutputAudioPortWasCalledWithNone(
    ) async throws {
        mockPolicy.stub(
            for: .configuration,
            with: AudioSessionConfiguration(
                category: .ambient,
                mode: .default,
                options: [.allowAirPlay]
            )
        )
        mockAudioSession.category = .playAndRecord

        try await subject.didUpdateCallSettings(.init(audioOn: false))

        XCTAssertEqual(mockAudioSession.timesCalled(.setCategory), 1)
        let payload = try XCTUnwrap(
            mockAudioSession.recordedInputPayload(
                (AVAudioSession.Category, AVAudioSession.Mode, AVAudioSession.CategoryOptions).self,
                for: .setCategory
            )?.first
        )
        XCTAssertEqual(payload.0, .ambient)
        XCTAssertEqual(payload.1, .default)
        XCTAssertEqual(payload.2, [.allowAirPlay])
    }

    func test_didUpdateCallSettings_policyReturnsConfiguration_audioSessionWasCalledWithExpectedConfiguration() async throws {
        mockPolicy.stub(
            for: .configuration,
            with: AudioSessionConfiguration(
                category: .ambient,
                mode: .default,
                options: []
            )
        )
        mockAudioSession.category = .playAndRecord

        try await subject.didUpdateCallSettings(.init(audioOn: false))

        XCTAssertEqual(mockAudioSession.timesCalled(.overrideOutputAudioPort), 1)
        let payload = try XCTUnwrap(
            mockAudioSession
                .recordedInputPayload(AVAudioSession.PortOverride.self, for: .overrideOutputAudioPort)?.first
        )
        XCTAssertEqual(payload, .none)
    }

    func test_didUpdateCallSettings_policyReturnsConfigurationWithOverrideOutputAudioPort_audioSessionWasCalledWithExpectedOverrideOutputAudioPort(
    ) async throws {
        mockPolicy.stub(
            for: .configuration,
            with: AudioSessionConfiguration(
                category: .playAndRecord,
                mode: .default,
                options: [],
                overrideOutputAudioPort: .speaker
            )
        )

        try await subject.didUpdateCallSettings(.init(audioOn: false))

        XCTAssertEqual(mockAudioSession.timesCalled(.overrideOutputAudioPort), 1)
        let payload = try XCTUnwrap(
            mockAudioSession
                .recordedInputPayload(AVAudioSession.PortOverride.self, for: .overrideOutputAudioPort)?.first
        )
        XCTAssertEqual(payload, .speaker)
    }

    func test_didUpdateCallSettings_policyReturnsSameConfigurationAsPreviously_audioSessionWasNotCalled() async throws {
        mockPolicy.stub(
            for: .configuration,
            with: AudioSessionConfiguration(
                category: .playAndRecord,
                mode: .default,
                options: [],
                overrideOutputAudioPort: .speaker
            )
        )

        try await subject.didUpdateCallSettings(.init(audioOn: false))
        try await subject.didUpdateCallSettings(.init(audioOn: false))

        XCTAssertEqual(mockAudioSession.timesCalled(.setCategory), 1)
    }

    // MARK: - didUpdatePolicy(_:)

    func test_didUpdatePolicy_policyWasCalled() async throws {
        try await assertConfigurationWasCalledOnPolicy({
            try await self.subject.didUpdatePolicy(self.mockPolicy)
        }, expectedInput: [(subject.activeCallSettings, subject.ownCapabilities)])
    }

    func test_didUpdatePolicy_withoutAnyChanges_policyWasCalledTwice() async throws {
        try await assertConfigurationWasCalledOnPolicy({
            try await self.subject.didUpdatePolicy(self.mockPolicy)
            try await self.subject.didUpdatePolicy(self.mockPolicy)
        }, expectedInput: [
            (subject.activeCallSettings, subject.ownCapabilities),
            (subject.activeCallSettings, subject.ownCapabilities)
        ])
    }

    // MARK: - prepareForRecording

    func test_prepareForRecording_whenAudioOff_setsAudioOn_andCallsSetCategory() async throws {
        subject = .init(
            callSettings: .init(audioOn: false),
            policy: mockPolicy,
            audioSession: mockAudioSession
        )
        
        try await assertConfigurationWasCalledOnPolicy({
            try await self.subject.prepareForRecording()
        }, expectedInput: [
            (.init(audioOn: true), subject.ownCapabilities)
        ])
        XCTAssertTrue(subject.activeCallSettings.audioOn)
    }

    func test_prepareForRecording_whenAudioAlreadyOn_doesNotCallSetCategory() async throws {
        subject = .init(
            callSettings: .init(audioOn: true),
            policy: mockPolicy,
            audioSession: mockAudioSession
        )

        try await subject.prepareForRecording()

        XCTAssertTrue(subject.activeCallSettings.audioOn)
        XCTAssertEqual(mockPolicy.timesCalled(.configuration), 0)
    }

    // MARK: - requestRecordPermission

    func test_requestRecordPermission_whenNotRecording_callsMockAudioSession() async {
        _ = await subject.requestRecordPermission()

        XCTAssertEqual(mockAudioSession.timesCalled(.requestRecordPermission), 1)
    }

    func test_requestRecordPermission_whenIsRecording_doesNotCallSession() async {
        subject.isRecording = true
        _ = await subject.requestRecordPermission()

        XCTAssertEqual(mockAudioSession.timesCalled(.requestRecordPermission), 0)
    }

    // MARK: - dismantle

    func test_dismantle_resetsGlobalCurrentValue() {
        subject.dismantle()

        XCTAssertNil(StreamAudioSession.currentValue)
    }

    // MARK: - callKitActivated

    func test_callKitActivated_configurationWasCalledOnPolicy() async throws {
        let mockPolicy = MockAudioSessionPolicy()
        try await subject.didUpdatePolicy(mockPolicy)
        let audioSession = MockAVAudioSession()

        try subject.callKitActivated(audioSession)

        // The expected value is 2 as the audioSession will call it once
        // when we first update the policy.
        XCTAssertEqual(mockPolicy.timesCalled(.configuration), 2)
    }

    func test_callKitActivated_providedAudioSessionSetCategoryWasCalledCorrectly() async throws {
        let mockPolicy = MockAudioSessionPolicy()
        mockPolicy.stub(
            for: .configuration,
            with: AudioSessionConfiguration(
                category: .playAndRecord,
                mode: .voiceChat,
                options: .mixWithOthers,
                overrideOutputAudioPort: .speaker
            )
        )
        try await subject.didUpdatePolicy(mockPolicy)
        let audioSession = MockAVAudioSession()

        try subject.callKitActivated(audioSession)

        let request = try XCTUnwrap(
            audioSession.recordedInputPayload(
                (
                    AVAudioSession.Category,
                    AVAudioSession.Mode,
                    AVAudioSession.CategoryOptions
                ).self,
                for: .setCategory
            )?.first
        )
        XCTAssertEqual(request.0, .playAndRecord)
        XCTAssertEqual(request.1, .voiceChat)
        XCTAssertTrue(request.2.contains(.mixWithOthers))
    }

    func test_callKitActivated_providedAudioSessionSetOverridePortWasCalledCorrectly() async throws {
        let mockPolicy = MockAudioSessionPolicy()
        mockPolicy.stub(
            for: .configuration,
            with: AudioSessionConfiguration(
                category: .playAndRecord,
                mode: .voiceChat,
                options: .mixWithOthers,
                overrideOutputAudioPort: .speaker
            )
        )
        try await subject.didUpdatePolicy(mockPolicy)
        let audioSession = MockAVAudioSession()

        try subject.callKitActivated(audioSession)

        let request = try XCTUnwrap(
            audioSession.recordedInputPayload(
                AVAudioSession.PortOverride.self,
                for: .setOverrideOutputAudioPort
            )?.first
        )
        XCTAssertEqual(request, .speaker)
    }

    // MARK: - Private Helpers

    private func assertConfigurationWasCalledOnPolicy(
        _ trigger: @escaping () async throws -> Void,
        expectedInput: @autoclosure () -> [(CallSettings, Set<OwnCapability>)]
    ) async throws {
        try await trigger()
        XCTAssertEqual(mockPolicy.timesCalled(.configuration), expectedInput().endIndex)
        let payloads = try XCTUnwrap(mockPolicy.recordedInputPayload((CallSettings, Set<OwnCapability>).self, for: .configuration))
        XCTAssertEqual(payloads.map(\.0), expectedInput().map(\.0))
        XCTAssertEqual(payloads.map(\.1), expectedInput().map(\.1))
    }
}
