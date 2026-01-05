//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
@testable import StreamVideo
import StreamWebRTC
import XCTest

final class AudioDeviceModule_Tests: XCTestCase, @unchecked Sendable {

    private var source: MockRTCAudioDeviceModule!
    private var audioEngineNodeAdapter: MockAudioEngineNodeAdapter!
    private var subject: AudioDeviceModule!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        source = .init()
        audioEngineNodeAdapter = .init()
        cancellables = []
    }

    override func tearDown() {
        cancellables = nil
        subject = nil
        audioEngineNodeAdapter = nil
        source = nil
        super.tearDown()
    }

    // MARK: - setPlayout

    func test_setPlayout_whenActivatingInitialized_callsStartPlayout() throws {
        makeSubject()
        source.stub(for: \.isPlayoutInitialized, with: true)

        try subject.setPlayout(true)

        XCTAssertEqual(source.timesCalled(.startPlayout), 1)
        XCTAssertEqual(source.timesCalled(.initAndStartPlayout), 0)
    }

    func test_setPlayout_whenActivatingNotInitialized_callsInitAndStartPlayout() throws {
        makeSubject()
        source.stub(for: \.isPlayoutInitialized, with: false)

        try subject.setPlayout(true)

        XCTAssertEqual(source.timesCalled(.initAndStartPlayout), 1)
        XCTAssertEqual(source.timesCalled(.startPlayout), 0)
    }

    func test_setPlayout_whenDeactivating_callsStopPlayout() throws {
        source.stub(for: \.isPlaying, with: true)
        makeSubject()

        try subject.setPlayout(false)

        XCTAssertEqual(source.timesCalled(.stopPlayout), 1)
    }

    func test_setPlayout_whenAlreadyPlaying_doesNothing() throws {
        source.stub(for: \.isPlaying, with: true)
        makeSubject()

        try subject.setPlayout(true)

        XCTAssertEqual(source.timesCalled(.startPlayout), 0)
        XCTAssertEqual(source.timesCalled(.initAndStartPlayout), 0)
    }

    func test_setPlayout_whenOperationFails_throwsClientError() {
        makeSubject()
        source.stub(for: \.isPlayoutInitialized, with: true)
        source.stub(for: .startPlayout, with: -1)

        XCTAssertThrowsError(try subject.setPlayout(true)) { error in
            XCTAssertTrue(error is ClientError)
        }
    }

    // MARK: - setRecording

    func test_setRecording_whenActivatingInitialized_callsStartRecording() throws {
        makeSubject()
        source.stub(for: \.isRecordingInitialized, with: true)

        try subject.setRecording(true)

        XCTAssertEqual(source.timesCalled(.startRecording), 1)
        XCTAssertEqual(source.timesCalled(.initAndStartRecording), 0)
    }

    func test_setRecording_whenActivatingNotInitialized_callsInitAndStartRecording() throws {
        makeSubject()
        source.stub(for: \.isRecordingInitialized, with: false)

        try subject.setRecording(true)

        XCTAssertEqual(source.timesCalled(.initAndStartRecording), 1)
        XCTAssertEqual(source.timesCalled(.startRecording), 0)
    }

    func test_setRecording_whenDeactivating_callsStopRecording() throws {
        source.stub(for: \.isRecording, with: true)
        makeSubject()

        try subject.setRecording(false)

        XCTAssertEqual(source.timesCalled(.stopRecording), 1)
    }

    func test_setRecording_whenAlreadyRecording_doesNothing() throws {
        source.stub(for: \.isRecording, with: true)
        makeSubject()

        try subject.setRecording(true)

        XCTAssertEqual(source.timesCalled(.startRecording), 0)
        XCTAssertEqual(source.timesCalled(.initAndStartRecording), 0)
        XCTAssertEqual(source.timesCalled(.stopRecording), 0)
    }

    // MARK: - setMuted

    func test_setMuted_whenStateUnchanged_doesNothing() throws {
        source.stub(for: \.isMicrophoneMuted, with: true)
        makeSubject()

        try subject.setMuted(true)

        XCTAssertEqual(source.timesCalled(.setMicrophoneMuted), 0)
    }

    func test_setMuted_whenMuting_updatesStateAndPublisher() throws {
        source.stub(for: \.isMicrophoneMuted, with: false)
        makeSubject()

        try subject.setMuted(true)

        XCTAssertEqual(source.timesCalled(.setMicrophoneMuted), 1)
        XCTAssertTrue(subject.isMicrophoneMuted)
    }

    func test_setMuted_whenUnmutingWhileRecordingStopped_startsRecordingBeforeUnmuting() throws {
        source.stub(for: \.isMicrophoneMuted, with: true)
        source.stub(for: \.isRecordingInitialized, with: false)
        makeSubject()

        try subject.setMuted(false)

        XCTAssertEqual(source.timesCalled(.initAndStartRecording), 1)
        XCTAssertEqual(source.timesCalled(.setMicrophoneMuted), 1)
        XCTAssertFalse(subject.isMicrophoneMuted)
    }

    // MARK: - Stereo playout

    func test_setStereoPlayoutPreference_updatesMuteModePreferenceAndVPBypassed() {
        makeSubject()

        subject.setStereoPlayoutPreference(true)
        XCTAssertTrue(source.prefersStereoPlayout)
        XCTAssertTrue(source.isVoiceProcessingBypassed)

        subject.setStereoPlayoutPreference(false)
        XCTAssertFalse(source.prefersStereoPlayout)
        XCTAssertFalse(source.isVoiceProcessingBypassed)

        let recordedModes = source.recordedInputPayload(RTCAudioEngineMuteMode.self, for: .setMuteMode)
        XCTAssertEqual(recordedModes, [.inputMixer, .voiceProcessing])

        let recordedPreparedFlags = source.recordedInputPayload(Bool.self, for: .setRecordingAlwaysPreparedMode)
        XCTAssertEqual(recordedPreparedFlags, [false, false])
    }

    func test_refreshStereoPlayoutState_invokesUnderlyingModule() {
        makeSubject()

        subject.refreshStereoPlayoutState()

        XCTAssertEqual(source.timesCalled(.refreshStereoPlayoutState), 1)
    }

    // MARK: - Reset

    func test_reset_invokesUnderlyingModule() {
        makeSubject()

        subject.reset()

        XCTAssertEqual(source.timesCalled(.reset), 1)
    }

    // MARK: - Delegate callbacks

    func test_didReceiveSpeechActivityEvent_started_emitsEvent() async {
        makeSubject()
        await expectEvent(.speechActivityStarted) {
            subject.audioDeviceModule($0, didReceiveSpeechActivityEvent: .started)
        }
    }

    func test_didReceiveSpeechActivityEvent_ended_emitsEvent() async {
        makeSubject()
        await expectEvent(.speechActivityEnded) {
            subject.audioDeviceModule($0, didReceiveSpeechActivityEvent: .ended)
        }
    }

    func test_willEnableEngine_emitsEventAndUpdatesState() async {
        makeSubject()
        let engine = AVAudioEngine()
        let expectedEvent = AudioDeviceModule.Event.willEnableAudioEngine(
            engine,
            isPlayoutEnabled: true,
            isRecordingEnabled: false
        )

        await expectEvent(
            expectedEvent,
            isPlayoutEnabled: true,
            isRecordingEnabled: false
        ) {
            _ = subject.audioDeviceModule(
                $0,
                willEnableEngine: engine,
                isPlayoutEnabled: true,
                isRecordingEnabled: false
            )
        }

        XCTAssertTrue(subject.isPlaying)
        XCTAssertFalse(subject.isRecording)
    }

    func test_willReleaseEngine_emitsEventAndUninstallsTap() async {
        makeSubject()
        let engine = AVAudioEngine()

        await expectEvent(.willReleaseAudioEngine(engine)) {
            _ = subject.audioDeviceModule($0, willReleaseEngine: engine)
        }

        XCTAssertEqual(audioEngineNodeAdapter.timesCalled(.uninstall), 1)
        XCTAssertEqual(audioEngineNodeAdapter.recordedInputPayload(Int.self, for: .uninstall)?.first, 0)
    }

    func test_configureInputFromSource_installsTap() {
        makeSubject()
        let engine = AVAudioEngine()
        let destination = AVAudioMixerNode()
        let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 48000,
            channels: 1,
            interleaved: false
        )!

        _ = subject.audioDeviceModule(
            .init(),
            engine: engine,
            configureInputFromSource: nil,
            toDestination: destination,
            format: format,
            context: [:]
        )

        XCTAssertEqual(audioEngineNodeAdapter.timesCalled(.installInputTap), 1)
        let payload = audioEngineNodeAdapter
            .recordedInputPayload((Int, UInt32).self, for: .installInputTap)?
            .first
        XCTAssertEqual(payload?.0, 0)
        XCTAssertEqual(payload?.1, 1024)
    }

    func test_configureInputFromSource_emitsEvent() async {
        makeSubject()
        let engine = AVAudioEngine()
        let sourceNode = AVAudioPlayerNode()
        let destination = AVAudioMixerNode()
        let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 48000,
            channels: 1,
            interleaved: false
        )!
        let expectedEvent = AudioDeviceModule.Event.configureInputFromSource(
            engine,
            source: sourceNode,
            destination: destination,
            format: format
        )

        await expectEvent(expectedEvent) {
            _ = subject.audioDeviceModule(
                $0,
                engine: engine,
                configureInputFromSource: sourceNode,
                toDestination: destination,
                format: format,
                context: [:]
            )
        }
    }

    func test_configureOutputFromSource_emitsEvent() async {
        makeSubject()
        let engine = AVAudioEngine()
        let sourceNode = AVAudioPlayerNode()
        let destination = AVAudioMixerNode()
        let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 48000,
            channels: 2,
            interleaved: false
        )!
        let expectedEvent = AudioDeviceModule.Event.configureOutputFromSource(
            engine,
            source: sourceNode,
            destination: destination,
            format: format
        )

        await expectEvent(expectedEvent) {
            _ = subject.audioDeviceModule(
                $0,
                engine: engine,
                configureOutputFromSource: sourceNode,
                toDestination: destination,
                format: format,
                context: [:]
            )
        }
    }

    func test_didUpdateAudioProcessingState_updatesPublishersAndEmitsEvent() async {
        makeSubject()
        let expectedEvent = AudioDeviceModule.Event.didUpdateAudioProcessingState(
            voiceProcessingEnabled: true,
            voiceProcessingBypassed: false,
            voiceProcessingAGCEnabled: true,
            stereoPlayoutEnabled: true
        )

        await expectEvent(expectedEvent) {
            subject.audioDeviceModule(
                $0,
                didUpdateAudioProcessingState: RTCAudioProcessingState(
                    voiceProcessingEnabled: true,
                    voiceProcessingBypassed: false,
                    voiceProcessingAGCEnabled: true,
                    stereoPlayoutEnabled: true
                )
            )
        }

        XCTAssertTrue(subject.isVoiceProcessingEnabled)
        XCTAssertFalse(subject.isVoiceProcessingBypassed)
        XCTAssertTrue(subject.isVoiceProcessingAGCEnabled)
        XCTAssertTrue(subject.isStereoPlayoutEnabled)
    }

    // MARK: - Helpers

    @discardableResult
    private func makeSubject() -> AudioDeviceModule {
        let module = AudioDeviceModule(
            source,
            audioLevelsNodeAdapter: audioEngineNodeAdapter
        )
        subject = module
        return module
    }

    private func expectEvent(
        _ expectedEvent: AudioDeviceModule.Event,
        isPlayoutEnabled: Bool? = nil,
        isRecordingEnabled: Bool? = nil,
        operation: (RTCAudioDeviceModule) -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        guard subject != nil else {
            XCTFail("Subject not initialized", file: file, line: line)
            return
        }

        let eventExpectation = expectation(description: "Expect \(expectedEvent)")
        subject.publisher
            .filter { $0 == expectedEvent }
            .sink { _ in eventExpectation.fulfill() }
            .store(in: &cancellables)

        var expectations = [eventExpectation]

        if let isPlayoutEnabled {
            let playoutExpectation = expectation(description: "isPlaying updated")
            subject.isPlayingPublisher
                .dropFirst()
                .filter { $0 == isPlayoutEnabled }
                .sink { _ in playoutExpectation.fulfill() }
                .store(in: &cancellables)
            expectations.append(playoutExpectation)
        }

        if let isRecordingEnabled {
            let recordingExpectation = expectation(description: "isRecording updated")
            subject.isRecordingPublisher
                .dropFirst()
                .filter { $0 == isRecordingEnabled }
                .sink { _ in recordingExpectation.fulfill() }
                .store(in: &cancellables)
            expectations.append(recordingExpectation)
        }

        operation(.init())
        await safeFulfillment(of: expectations, file: file, line: line)
        cancellables.removeAll()
    }
}
