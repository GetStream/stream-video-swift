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

    // MARK: - resetPlayout

    func test_resetPlayout_whenPlayoutInitialized_restartsPlayout() {
        source.stub(for: \.isPlaying, with: true)
        source.stub(for: \.isPlayoutInitialized, with: true)
        makeSubject()

        subject.resetPlayout()

        XCTAssertEqual(source.timesCalled(.stopPlayout), 1)
        XCTAssertEqual(source.timesCalled(.startPlayout), 1)
        XCTAssertEqual(source.timesCalled(.initAndStartPlayout), 0)
    }

    func test_resetPlayout_whenPlayoutNotInitialized_reinitializesPlayout() {
        source.stub(for: \.isPlaying, with: true)
        source.stub(for: \.isPlayoutInitialized, with: false)
        makeSubject()

        subject.resetPlayout()

        XCTAssertEqual(source.timesCalled(.stopPlayout), 1)
        XCTAssertEqual(source.timesCalled(.startPlayout), 0)
        XCTAssertEqual(source.timesCalled(.initAndStartPlayout), 1)
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

    func test_setRecording_whenNativeStartUnmutes_restoresMuteBeforePublishingRecording() throws {
        source.stub(for: \.isMicrophoneMuted, with: true)
        source.stub(for: \.isRecordingInitialized, with: true)
        makeSubject()
        var muteCallCountWhenRecordingWasPublished: Int?
        subject.isRecordingPublisher
            .dropFirst()
            .sink { [weak source] isRecording in
                guard isRecording else { return }
                muteCallCountWhenRecordingWasPublished =
                    source?.timesCalled(.setMicrophoneMuted)
            }
            .store(in: &cancellables)
        source.onInvoke = { [weak source] function in
            guard function == .startRecording else { return }
            source?.stub(for: \.isMicrophoneMuted, with: false)
        }

        try subject.setRecording(true)

        XCTAssertEqual(
            source.recordedInputPayload(Bool.self, for: .setMicrophoneMuted),
            [true]
        )
        XCTAssertEqual(muteCallCountWhenRecordingWasPublished, 1)
        XCTAssertTrue(subject.isMicrophoneMuted)
    }

    func test_setRecording_whenMuteRestorationFails_stopsRecording() {
        source.stub(for: \.isMicrophoneMuted, with: true)
        source.stub(for: \.isRecordingInitialized, with: true)
        source.stub(for: .setMicrophoneMuted, with: -1)
        makeSubject()
        source.onInvoke = { [weak source] function in
            guard function == .startRecording else { return }
            source?.stub(for: \.isMicrophoneMuted, with: false)
        }

        XCTAssertThrowsError(try subject.setRecording(true))

        XCTAssertEqual(source.timesCalled(.stopRecording), 1)
        XCTAssertFalse(subject.isRecording)
    }

    func test_setRecording_whenMuteRestorationAndRollbackFail_reconcilesState() {
        source.stub(for: \.isMicrophoneMuted, with: true)
        source.stub(for: \.isRecordingInitialized, with: true)
        source.stub(for: .setMicrophoneMuted, with: -1)
        source.stub(for: .stopRecording, with: -1)
        makeSubject()
        source.onInvoke = { [weak source] function in
            guard function == .startRecording else { return }
            source?.stub(for: \.isMicrophoneMuted, with: false)
        }

        XCTAssertThrowsError(try subject.setRecording(true))

        XCTAssertFalse(subject.isRecording)
        XCTAssertFalse(subject.isMicrophoneMuted)
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

    func test_setMuted_whenNativeStateAlreadyMatches_reconcilesCachedState() throws {
        source.stub(for: \.isMicrophoneMuted, with: true)
        makeSubject()
        source.stub(for: \.isMicrophoneMuted, with: false)

        try subject.setMuted(false)

        XCTAssertEqual(source.timesCalled(.setMicrophoneMuted), 0)
        XCTAssertFalse(subject.isMicrophoneMuted)
    }

    func test_setMuted_whenMuting_updatesStateAndPublisher() throws {
        source.stub(for: \.isMicrophoneMuted, with: false)
        makeSubject()

        try subject.setMuted(true)

        XCTAssertEqual(source.timesCalled(.setMicrophoneMuted), 1)
        XCTAssertTrue(subject.isMicrophoneMuted)
        XCTAssertEqual(source.timesCalled(.setMuteMode), 0)
    }

    func test_setMuted_neverMusicUnmute_doesNotStopRecording() throws {
        source.stub(for: \.isMicrophoneMuted, with: false)
        source.stub(for: \.isRecordingInitialized, with: true)
        makeSubject()
        try subject.setRecording(true)
        try subject.setMuted(true)
        source.stub(for: \.isMicrophoneMuted, with: true)
        let stopCount = source.timesCalled(.stopRecording)

        try subject.setMuted(false)

        XCTAssertEqual(source.timesCalled(.stopRecording), stopCount)
        XCTAssertEqual(source.timesCalled(.setMicrophoneMuted), 2)
        XCTAssertEqual(source.timesCalled(.stopPlayout), 0)
        XCTAssertFalse(subject.isMicrophoneMuted)
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

        let recordedModes = source.recordedInputPayload(
            RTCAudioEngineMuteMode.self,
            for: .setMuteMode
        )
        XCTAssertEqual(recordedModes, [.inputMixer, .voiceProcessing])

        XCTAssertEqual(source.timesCalled(.setVoiceProcessingEnabled), 0)

        let recordedPreparedFlags = source.recordedInputPayload(
            Bool.self,
            for: .setRecordingAlwaysPreparedMode
        )
        XCTAssertEqual(recordedPreparedFlags, [false])
    }

    func test_setMusicCaptureEnabled_music_bypassesVPAndDisablesAGC() throws {
        makeSubject()

        try subject.setMusicCaptureEnabled(true)

        XCTAssertFalse(source.isVoiceProcessingAGCEnabled)
        XCTAssertTrue(source.isVoiceProcessingBypassed)
        XCTAssertFalse(source.isVoiceProcessingEnabled)
        XCTAssertEqual(
            source.recordedInputPayload(Bool.self, for: .setVoiceProcessingEnabled),
            [false]
        )
        XCTAssertEqual(
            source.recordedInputPayload(RTCAudioEngineMuteMode.self, for: .setMuteMode),
            [.inputMixer]
        )
    }

    func test_setMusicCaptureEnabled_voice_restoresAGC() throws {
        makeSubject()
        try subject.setMusicCaptureEnabled(true)

        try subject.setMusicCaptureEnabled(false)

        XCTAssertTrue(source.isVoiceProcessingAGCEnabled)
        XCTAssertFalse(source.isVoiceProcessingBypassed)
        XCTAssertTrue(source.isVoiceProcessingEnabled)
        XCTAssertEqual(
            source.recordedInputPayload(Bool.self, for: .setVoiceProcessingEnabled)?.last,
            true
        )
        XCTAssertEqual(
            source.recordedInputPayload(
                RTCAudioEngineMuteMode.self,
                for: .setMuteMode
            )?.last,
            .voiceProcessing
        )
    }

    func test_setMusicCaptureEnabled_voice_withStereo_keepsVPDisabled() throws {
        makeSubject()
        subject.setStereoPlayoutPreference(true)
        try subject.setMusicCaptureEnabled(true)

        try subject.setMusicCaptureEnabled(false)

        XCTAssertEqual(
            source.recordedInputPayload(Bool.self, for: .setVoiceProcessingEnabled)?.last,
            false
        )
    }

    func test_setStereoPlayoutPreference_afterVoiceWhileStereo_reEnablesVP(
    ) throws {
        makeSubject()
        subject.setStereoPlayoutPreference(true)
        try subject.setMusicCaptureEnabled(true)
        try subject.setMusicCaptureEnabled(false)

        XCTAssertFalse(source.isVoiceProcessingEnabled)

        subject.setStereoPlayoutPreference(false)

        XCTAssertTrue(source.isVoiceProcessingEnabled)
        XCTAssertFalse(source.isVoiceProcessingBypassed)
        XCTAssertEqual(
            source.recordedInputPayload(
                Bool.self,
                for: .setVoiceProcessingEnabled
            )?.last,
            true
        )
        XCTAssertEqual(
            source.recordedInputPayload(
                RTCAudioEngineMuteMode.self,
                for: .setMuteMode
            )?.last,
            .voiceProcessing
        )
    }

    func test_setStereoPlayoutPreference_afterVoiceWhileStereoWhileMuted_defersVPUntilUnmute(
    ) throws {
        source.stub(for: \.isMicrophoneMuted, with: false)
        makeSubject()
        subject.setStereoPlayoutPreference(true)
        try subject.setMusicCaptureEnabled(true)
        try subject.setMusicCaptureEnabled(false)
        try subject.setMuted(true)
        source.stub(for: \.isMicrophoneMuted, with: true)

        subject.setStereoPlayoutPreference(false)

        XCTAssertFalse(source.isVoiceProcessingEnabled)
        XCTAssertEqual(
            source.recordedInputPayload(
                RTCAudioEngineMuteMode.self,
                for: .setMuteMode
            )?.last,
            .inputMixer
        )

        try subject.setMuted(false)

        XCTAssertTrue(source.isVoiceProcessingEnabled)
        XCTAssertEqual(
            source.recordedInputPayload(
                Bool.self,
                for: .setVoiceProcessingEnabled
            )?.last,
            true
        )
        XCTAssertEqual(
            source.recordedInputPayload(
                RTCAudioEngineMuteMode.self,
                for: .setMuteMode
            )?.last,
            .voiceProcessing
        )
    }

    func test_setMusicCaptureEnabled_voiceStandard_doesNotRestorePlayout() throws {
        source.stub(for: \.isPlaying, with: true)
        makeSubject()

        try subject.setMusicCaptureEnabled(false)

        XCTAssertEqual(source.timesCalled(.stopPlayout), 0)
        XCTAssertEqual(source.timesCalled(.initAndStartPlayout), 0)
        XCTAssertEqual(source.timesCalled(.startPlayout), 0)
    }

    func test_setMusicCaptureEnabled_music_restoresPlayoutWhenPlaying() throws {
        source.stub(for: \.isPlaying, with: true)
        makeSubject()

        try subject.setMusicCaptureEnabled(true)

        XCTAssertEqual(source.timesCalled(.stopPlayout), 1)
        XCTAssertEqual(source.timesCalled(.initAndStartPlayout), 1)
        XCTAssertEqual(source.timesCalled(.startPlayout), 0)
    }

    func test_setMusicCaptureEnabled_music_restoresPlayoutWhenInitialized() throws {
        source.stub(for: \.isPlayoutInitialized, with: true)
        makeSubject()

        try subject.setMusicCaptureEnabled(true)

        XCTAssertEqual(source.timesCalled(.stopPlayout), 1)
        XCTAssertEqual(source.timesCalled(.startPlayout), 1)
        XCTAssertEqual(source.timesCalled(.initAndStartPlayout), 0)
    }

    func test_setMusicCaptureEnabled_music_skipsPlayoutRestoreWhenIdle() throws {
        makeSubject()

        try subject.setMusicCaptureEnabled(true)

        XCTAssertEqual(source.timesCalled(.stopPlayout), 0)
        XCTAssertEqual(source.timesCalled(.initAndStartPlayout), 0)
        XCTAssertEqual(source.timesCalled(.startPlayout), 0)
    }

    func test_setMusicCaptureEnabled_music_restoresPlayoutWhenRequested() throws {
        makeSubject()

        try subject.setMusicCaptureEnabled(
            true,
            restorePlayout: true
        )

        XCTAssertEqual(source.timesCalled(.stopPlayout), 1)
        XCTAssertEqual(source.timesCalled(.initAndStartPlayout), 1)
        XCTAssertEqual(source.timesCalled(.startPlayout), 0)
    }

    func test_setMusicCaptureEnabled_whenAlreadyEnabled_doesNotReapply() throws {
        source.stub(for: \.isPlaying, with: true)
        makeSubject()
        try subject.setMusicCaptureEnabled(true)
        let vpCount = source.timesCalled(.setVoiceProcessingEnabled)
        let playoutStops = source.timesCalled(.stopPlayout)

        try subject.setMusicCaptureEnabled(true)

        XCTAssertEqual(source.timesCalled(.setVoiceProcessingEnabled), vpCount)
        XCTAssertEqual(source.timesCalled(.stopPlayout), playoutStops)
    }

    func test_setMusicCaptureEnabled_whenVPDisableFails_revertsSoRetryApplies(
    ) throws {
        makeSubject()
        source.stub(for: .setVoiceProcessingEnabled, with: 1)

        XCTAssertThrowsError(try subject.setMusicCaptureEnabled(true))

        // Desired stays set and applied stays stale so retry is not a
        // no-op; otherwise music stays VoiceChat-off / VP-on.
        source.stub(for: .setVoiceProcessingEnabled, with: 0)
        try subject.setMusicCaptureEnabled(true)

        XCTAssertEqual(
            source.recordedInputPayload(
                Bool.self,
                for: .setVoiceProcessingEnabled
            )?.last,
            false
        )
    }

    func test_setMusicCaptureEnabled_whenUnmuteVPDisableFails_retryApplies(
    ) throws {
        source.stub(for: \.isMicrophoneMuted, with: false)
        makeSubject()
        try subject.setMuted(true)
        source.stub(for: \.isMicrophoneMuted, with: true)
        try subject.setMusicCaptureEnabled(true)

        source.stub(for: .setVoiceProcessingEnabled, with: 1)
        XCTAssertThrowsError(try subject.setMuted(false))
        source.stub(for: \.isMicrophoneMuted, with: false)

        let vpCount = source.timesCalled(.setVoiceProcessingEnabled)
        source.stub(for: .setVoiceProcessingEnabled, with: 0)
        try subject.setMusicCaptureEnabled(true)

        XCTAssertGreaterThan(
            source.timesCalled(.setVoiceProcessingEnabled),
            vpCount
        )
        XCTAssertEqual(
            source.recordedInputPayload(
                Bool.self,
                for: .setVoiceProcessingEnabled
            )?.last,
            false
        )
    }

    func test_setMusicCaptureEnabled_music_whileMuted_doesNotLiftMuteOrToggleVP(
    ) throws {
        source.stub(for: \.isMicrophoneMuted, with: false)
        makeSubject()
        try subject.setMuted(true)
        source.stub(for: \.isMicrophoneMuted, with: true)
        let vpCount = source.timesCalled(.setVoiceProcessingEnabled)

        try subject.setMusicCaptureEnabled(true)
        try subject.setMusicCaptureEnabled(false)

        XCTAssertEqual(source.timesCalled(.setVoiceProcessingEnabled), vpCount)
        XCTAssertEqual(
            source.recordedInputPayload(Bool.self, for: .setMicrophoneMuted)?
                .contains(false),
            false
        )
        XCTAssertTrue(subject.isMicrophoneMuted)
    }

    func test_setMusicCaptureEnabled_musicOffWhileMuted_enablesVPOnUnmute(
    ) throws {
        source.stub(for: \.isMicrophoneMuted, with: false)
        source.stub(for: \.isRecordingInitialized, with: true)
        makeSubject()
        try subject.setRecording(true)
        try subject.setMusicCaptureEnabled(true)
        try subject.setMuted(true)
        source.stub(for: \.isMicrophoneMuted, with: true)
        let vpCount = source.timesCalled(.setVoiceProcessingEnabled)
        let stopCount = source.timesCalled(.stopRecording)

        try subject.setMusicCaptureEnabled(false)

        XCTAssertEqual(source.timesCalled(.setVoiceProcessingEnabled), vpCount)

        try subject.setMuted(false)

        XCTAssertEqual(
            source.recordedInputPayload(Bool.self, for: .setVoiceProcessingEnabled)?
                .last,
            true
        )
        XCTAssertEqual(
            source.recordedInputPayload(
                RTCAudioEngineMuteMode.self,
                for: .setMuteMode
            )?.last,
            .voiceProcessing
        )
        XCTAssertEqual(source.timesCalled(.stopRecording), stopCount)
        XCTAssertFalse(subject.isMicrophoneMuted)
    }

    func test_setMusicCaptureEnabled_musicWhileMuted_restoresPlayoutOnUnmute(
    ) throws {
        source.stub(for: \.isPlaying, with: true)
        makeSubject()
        try subject.setMuted(true)
        source.stub(for: \.isMicrophoneMuted, with: true)

        try subject.setMusicCaptureEnabled(true)

        XCTAssertEqual(source.timesCalled(.stopPlayout), 0)

        try subject.setMuted(false)

        XCTAssertEqual(source.timesCalled(.stopPlayout), 1)
        XCTAssertEqual(source.timesCalled(.initAndStartPlayout), 1)
    }

    func test_setMusicCaptureEnabled_music_whileUnmuted_doesNotTouchMute() throws {
        makeSubject()

        try subject.setMusicCaptureEnabled(true)

        XCTAssertEqual(source.timesCalled(.setMicrophoneMuted), 0)
    }

    func test_setMutedSpeechDetectionEnabled_updatesRecordingAlwaysPreparedMode() throws {
        source.stub(for: \.isRecordingAlwaysPreparedMode, with: false)
        makeSubject()

        try subject.setMutedSpeechDetectionEnabled(true)

        XCTAssertTrue(subject.isMutedSpeechDetectionEnabled)
        XCTAssertEqual(
            source.recordedInputPayload(Bool.self, for: .setRecordingAlwaysPreparedMode),
            [true]
        )
    }

    func test_setMutedSpeechDetectionEnabled_whenStateUnchanged_doesNothing() throws {
        source.stub(for: \.isRecordingAlwaysPreparedMode, with: true)
        makeSubject()

        try subject.setMutedSpeechDetectionEnabled(true)

        XCTAssertTrue(subject.isMutedSpeechDetectionEnabled)
        XCTAssertEqual(source.timesCalled(.setRecordingAlwaysPreparedMode), 0)
    }

    func test_setEngineAvailability_updatesInputAndOutputAvailability() throws {
        makeSubject()

        try subject.setEngineAvailability(false)

        let availability = source.recordedInputPayload(
            (Bool, Bool).self,
            for: .setEngineAvailability
        )?.last
        XCTAssertEqual(availability?.0, false)
        XCTAssertEqual(availability?.1, false)
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

    // MARK: - Concurrent engine access

    /// The `AVAudioEngine` graph behind the ADM is not thread-safe. Store
    /// middleware, `StereoPlayoutEffect` (its own queue) and the stats collector
    /// each drive the ADM from independent queues, so two engine mutations must
    /// never overlap. Overlap is what makes WebRTC's `setVoiceProcessingEnabled`
    /// graph connect throw and abort the app (regression seen since 1.48.0).
    func test_engineMutations_fromConcurrentQueues_areSerialized() {
        makeSubject()
        source.stub(for: \.isRecordingInitialized, with: false)
        let overlapDetectionWindow: TimeInterval = 1

        let op1Entered = expectation(description: "setRecording entered the ADM")
        let op1Release = DispatchSemaphore(value: 0)
        let op1Finished = expectation(description: "setRecording finished")
        let op2Finished = expectation(description: "refreshStereoPlayoutState finished")

        let op2OverlappedOp1 = expectation(
            description: "refreshStereoPlayoutState ran while setRecording was in-flight"
        )
        op2OverlappedOp1.isInverted = true

        let op1InFlight = Atomic<Bool>(wrappedValue: false)

        source.onInvoke = { key in
            switch key {
            case .initAndStartRecording:
                op1InFlight.mutate { _ in true }
                op1Entered.fulfill()
                op1Release.wait()
                op1InFlight.mutate { _ in false }
            case .refreshStereoPlayoutState:
                if op1InFlight.wrappedValue {
                    op2OverlappedOp1.fulfill()
                }
            default:
                break
            }
        }

        // Dedicated queues (default QoS) keep both operations off the shared
        // global pool and avoid priority-inversion noise from the gating
        // semaphore.
        DispatchQueue(label: "test.op1").async {
            try? self.subject.setRecording(true)
            op1Finished.fulfill()
        }
        wait(for: [op1Entered], timeout: defaultTimeout)

        DispatchQueue(label: "test.op2").async {
            self.subject.refreshStereoPlayoutState()
            op2Finished.fulfill()
        }
        wait(for: [op2OverlappedOp1], timeout: overlapDetectionWindow)

        op1Release.signal()
        wait(for: [op1Finished, op2Finished], timeout: defaultTimeout)
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
        let engine = configureInput().engine

        await expectEvent(.willReleaseAudioEngine(engine)) {
            _ = subject.audioDeviceModule($0, willReleaseEngine: engine)
        }

        XCTAssertEqual(audioEngineNodeAdapter.timesCalled(.uninstall), 1)
        XCTAssertEqual(
            audioEngineNodeAdapter.recordedInputPayload(Int.self, for: .uninstall)?.first,
            0
        )
    }

    func test_willReleaseEngine_whenDifferentEngine_doesNotUninstallLiveTap() {
        makeSubject()
        let live = configureInput()
        let stale = AVAudioEngine()

        _ = subject.audioDeviceModule(.init(), willReleaseEngine: stale)

        XCTAssertEqual(audioEngineNodeAdapter.timesCalled(.uninstall), 0)

        _ = subject.audioDeviceModule(.init(), willReleaseEngine: live.engine)

        XCTAssertEqual(audioEngineNodeAdapter.timesCalled(.uninstall), 1)
    }

    func test_didDisableEngine_musicRecordingRemains_keepsInputGraphUntilRelease() throws {
        makeSubject()
        try subject.setMusicCaptureEnabled(true)
        let live = configureInput()

        _ = subject.audioDeviceModule(
            .init(),
            didDisableEngine: live.engine,
            isPlayoutEnabled: false,
            isRecordingEnabled: true
        )

        XCTAssertEqual(audioEngineNodeAdapter.timesCalled(.uninstall), 0)

        _ = subject.audioDeviceModule(.init(), willReleaseEngine: live.engine)

        XCTAssertEqual(audioEngineNodeAdapter.timesCalled(.uninstall), 1)
    }

    func test_didStopEngine_musicRecordingRemains_keepsInputGraphUntilRelease() throws {
        makeSubject()
        try subject.setMusicCaptureEnabled(true)
        let live = configureInput()

        _ = subject.audioDeviceModule(
            .init(),
            didStopEngine: live.engine,
            isPlayoutEnabled: false,
            isRecordingEnabled: true
        )

        XCTAssertEqual(audioEngineNodeAdapter.timesCalled(.uninstall), 0)

        _ = subject.audioDeviceModule(.init(), willReleaseEngine: live.engine)

        XCTAssertEqual(audioEngineNodeAdapter.timesCalled(.uninstall), 1)
    }

    func test_didDisableEngine_thenWillRelease_uninstallsTap() {
        makeSubject()
        let live = configureInput()

        _ = subject.audioDeviceModule(
            .init(),
            didDisableEngine: live.engine,
            isPlayoutEnabled: false,
            isRecordingEnabled: true
        )

        XCTAssertEqual(audioEngineNodeAdapter.timesCalled(.uninstall), 0)

        _ = subject.audioDeviceModule(.init(), willReleaseEngine: live.engine)

        XCTAssertEqual(audioEngineNodeAdapter.timesCalled(.uninstall), 1)
    }

    func test_didCreateEngine_whenReplacingEngine_retainsPreviousEngineUntilRelease() {
        makeSubject()
        var firstEngine: AVAudioEngine? = AVAudioEngine()
        var secondEngine: AVAudioEngine? = AVAudioEngine()
        let weakFirstEngine = WeakEngineBox(firstEngine)
        let weakSecondEngine = WeakEngineBox(secondEngine)

        _ = subject.audioDeviceModule(.init(), didCreateEngine: firstEngine!)
        _ = subject.audioDeviceModule(.init(), didCreateEngine: secondEngine!)
        firstEngine = nil
        secondEngine = nil

        XCTAssertNotNil(weakFirstEngine.value)
        XCTAssertNotNil(weakSecondEngine.value)

        _ = subject.audioDeviceModule(.init(), willReleaseEngine: weakFirstEngine.value!)
        XCTAssertNil(weakFirstEngine.value)
        XCTAssertNotNil(weakSecondEngine.value)

        _ = subject.audioDeviceModule(.init(), willReleaseEngine: weakSecondEngine.value!)
        XCTAssertNil(weakSecondEngine.value)
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

    @discardableResult
    private func configureInput(
        engine: AVAudioEngine = AVAudioEngine(),
        destination: AVAudioMixerNode = AVAudioMixerNode()
    ) -> (engine: AVAudioEngine, destination: AVAudioMixerNode) {
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
        return (engine, destination)
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

private struct WeakEngineBox {
    weak var value: AVAudioEngine?

    init(_ value: AVAudioEngine?) {
        self.value = value
    }
}
