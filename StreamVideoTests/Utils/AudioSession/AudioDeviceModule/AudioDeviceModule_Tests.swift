//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
@testable import StreamVideo
import StreamWebRTC
import XCTest

// final class AudioDeviceModule_Tests: XCTestCase, @unchecked Sendable {
//
//    private lazy var source: MockRTCAudioDeviceModule! = .init()
//    private lazy var audioEngineNodeAdapter: MockAudioEngineNodeAdapter! = .init()
//    private lazy var subject: AudioDeviceModule! = .init(source, audioLevelsNodeAdapter: audioEngineNodeAdapter)
//
//    override func tearDown() {
//        subject = nil
//        source = nil
//        audioEngineNodeAdapter = nil
//        super.tearDown()
//    }
//
//    // MARK: - init
//
//    func test_init_subscribesOnMicrophoneMutePublisher() {
//        _ = subject
//
//        XCTAssertEqual(source.timesCalled(.microphoneMutedPublisher), 1)
//    }
//
//    // MARK: setRecording
//
//    func test_setRecording_isEnabledTrueIsRecordingTrue_noAction() throws {
//        subject = .init(source, isRecording: true)
//
//        try subject.setRecording(true)
//
//        XCTAssertEqual(source.timesCalled(.initAndStartRecording), 0)
//        XCTAssertEqual(source.timesCalled(.setMicrophoneMuted), 0)
//        XCTAssertEqual(source.timesCalled(.stopRecording), 0)
//    }
//
//    func test_setRecording_isEnabledTrueIsRecordingFalseIsMicrophoneMutedFalse_initAndStartRecording() throws {
//        subject = .init(source, isRecording: false)
//
//        try subject.setRecording(true)
//
//        XCTAssertEqual(source.timesCalled(.initAndStartRecording), 1)
//        XCTAssertEqual(source.timesCalled(.setMicrophoneMuted), 0)
//        XCTAssertEqual(source.timesCalled(.stopRecording), 0)
//    }
//
//    func test_setRecording_isEnabledTrueIsRecordingFalseIsMicrophoneMutedTrue_initAndStartRecordingAndSetMicrophoneMuted() throws {
//        subject = .init(source, isRecording: false)
//        source.stub(for: \.isMicrophoneMuted, with: true)
//
//        try subject.setRecording(true)
//
//        XCTAssertEqual(source.timesCalled(.initAndStartRecording), 1)
//        XCTAssertEqual(source.timesCalled(.setMicrophoneMuted), 1)
//        XCTAssertEqual(source.timesCalled(.stopRecording), 0)
//    }
//
//    func test_setRecording_isEnabledFalseIsRecordingFalse_noAction() throws {
//        subject = .init(source, isRecording: false)
//
//        try subject.setRecording(false)
//
//        XCTAssertEqual(source.timesCalled(.initAndStartRecording), 0)
//        XCTAssertEqual(source.timesCalled(.setMicrophoneMuted), 0)
//        XCTAssertEqual(source.timesCalled(.stopRecording), 0)
//    }
//
//    // MARK: - setMuted
//
//    func test_setMuted_isMutedTrueIsMicrophoneMutedTrue_noAction() throws {
//        source.microphoneMutedSubject.send(true)
//        subject = .init(source, isMicrophoneMuted: true)
//
//        try subject.setMuted(true)
//
//        XCTAssertEqual(source.timesCalled(.setMicrophoneMuted), 0)
//    }
//
//    func test_setMuted_isMutedTrueIsMicrophoneMutedFalse_setMicrophoneMutedAndSubjectSend() async throws {
//        source.microphoneMutedSubject.send(false)
//        subject = .init(source, isMicrophoneMuted: false)
//
//        let sinkExpectation = expectation(description: "Sink was called.")
//        let cancellable = subject
//            .isMicrophoneMutedPublisher
//            .filter { $0 == true }
//            .sink { _ in sinkExpectation.fulfill() }
//
//        try subject.setMuted(true)
//
//        XCTAssertEqual(source.timesCalled(.setMicrophoneMuted), 1)
//        await safeFulfillment(of: [sinkExpectation])
//        cancellable.cancel()
//    }
//
//    func test_setMuted_isMutedFalseIsMicrophoneMutedTrue_setMicrophoneMutedAndSubjectSend() async throws {
//        source.microphoneMutedSubject.send(true)
//        subject = .init(source, isMicrophoneMuted: true)
//
//        let sinkExpectation = expectation(description: "Sink was called.")
//        let cancellable = subject
//            .isMicrophoneMutedPublisher
//            .filter { $0 == false }
//            .sink { _ in sinkExpectation.fulfill() }
//
//        try subject.setMuted(false)
//
//        XCTAssertEqual(source.timesCalled(.setMicrophoneMuted), 1)
//        await safeFulfillment(of: [sinkExpectation])
//        cancellable.cancel()
//    }
//
//    func test_setMuted_isMutedFalseIsMicrophoneMutedFalse_noAction() throws {
//        source.microphoneMutedSubject.send(false)
//        subject = .init(source, isMicrophoneMuted: false)
//
//        try subject.setMuted(false)
//
//        XCTAssertEqual(source.timesCalled(.setMicrophoneMuted), 0)
//    }
//
//    // MARK: - didReceiveSpeechActivityEvent
//
//    func test_didReceiveSpeechActivityEvent_speechActivityStarted_publishesEvent() async throws {
//        try await assertEvent(.speechActivityStarted) {
//            subject.audioDeviceModule($0, didReceiveSpeechActivityEvent: .started)
//        }
//    }
//
//    func test_didReceiveSpeechActivityEvent_speechActivityEnded_publishesEvent() async throws {
//        try await assertEvent(.speechActivityEnded) {
//            subject.audioDeviceModule($0, didReceiveSpeechActivityEvent: .ended)
//        }
//    }
//
//    // MARK: - didCreateEngine
//
//    func test_didCreateEngine_publishesEvent() async throws {
//        let audioEngine = AVAudioEngine()
//        try await assertEvent(.didCreateAudioEngine(audioEngine)) {
//            _ = subject.audioDeviceModule($0, didCreateEngine: audioEngine)
//        }
//    }
//
//    // MARK: - willEnableAudioEngine
//
//    func test_willEnableEngine_isPlayoutEnabledFalse_isRecordingEnabledFalse_publishesEvent() async throws {
//        let audioEngine = AVAudioEngine()
//        let isPlayoutEnabled = false
//        let isRecordingEnabled = false
//        try await assertEvent(
//            .willEnableAudioEngine(audioEngine),
//            isPlayoutEnabled: isPlayoutEnabled,
//            isRecordingEnabled: isRecordingEnabled
//        ) {
//            _ = subject.audioDeviceModule(
//                $0,
//                willEnableEngine: audioEngine,
//                isPlayoutEnabled: isPlayoutEnabled,
//                isRecordingEnabled: isRecordingEnabled
//            )
//        }
//    }
//
//    func test_willEnableEngine_isPlayoutEnabledTrue_isRecordingEnabledFalse_publishesEvent() async throws {
//        let audioEngine = AVAudioEngine()
//        let isPlayoutEnabled = true
//        let isRecordingEnabled = false
//        try await assertEvent(
//            .willEnableAudioEngine(audioEngine),
//            isPlayoutEnabled: isPlayoutEnabled,
//            isRecordingEnabled: isRecordingEnabled
//        ) {
//            _ = subject.audioDeviceModule(
//                $0,
//                willEnableEngine: audioEngine,
//                isPlayoutEnabled: isPlayoutEnabled,
//                isRecordingEnabled: isRecordingEnabled
//            )
//        }
//    }
//
//    func test_willEnableEngine_isPlayoutEnabledFalse_isRecordingEnabledTrue_publishesEvent() async throws {
//        let audioEngine = AVAudioEngine()
//        let isPlayoutEnabled = false
//        let isRecordingEnabled = true
//        try await assertEvent(
//            .willEnableAudioEngine(audioEngine),
//            isPlayoutEnabled: isPlayoutEnabled,
//            isRecordingEnabled: isRecordingEnabled
//        ) {
//            _ = subject.audioDeviceModule(
//                $0,
//                willEnableEngine: audioEngine,
//                isPlayoutEnabled: isPlayoutEnabled,
//                isRecordingEnabled: isRecordingEnabled
//            )
//        }
//    }
//
//    func test_willEnableEngine_isPlayoutEnabledTrue_isRecordingEnabledTrue_publishesEvent() async throws {
//        let audioEngine = AVAudioEngine()
//        let isPlayoutEnabled = true
//        let isRecordingEnabled = true
//        try await assertEvent(
//            .willEnableAudioEngine(audioEngine),
//            isPlayoutEnabled: isPlayoutEnabled,
//            isRecordingEnabled: isRecordingEnabled
//        ) {
//            _ = subject.audioDeviceModule(
//                $0,
//                willEnableEngine: audioEngine,
//                isPlayoutEnabled: isPlayoutEnabled,
//                isRecordingEnabled: isRecordingEnabled
//            )
//        }
//    }
//
//    // MARK: - willStartEngine
//
//    func test_willStartEngine_isPlayoutEnabledFalse_isRecordingEnabledFalse_publishesEvent() async throws {
//        let audioEngine = AVAudioEngine()
//        let isPlayoutEnabled = false
//        let isRecordingEnabled = false
//        try await assertEvent(
//            .willStartAudioEngine(audioEngine),
//            isPlayoutEnabled: isPlayoutEnabled,
//            isRecordingEnabled: isRecordingEnabled
//        ) {
//            _ = subject.audioDeviceModule(
//                $0,
//                willStartEngine: audioEngine,
//                isPlayoutEnabled: isPlayoutEnabled,
//                isRecordingEnabled: isRecordingEnabled
//            )
//        }
//    }
//
//    func test_willStartEngine_isPlayoutEnabledTrue_isRecordingEnabledFalse_publishesEvent() async throws {
//        let audioEngine = AVAudioEngine()
//        let isPlayoutEnabled = true
//        let isRecordingEnabled = false
//        try await assertEvent(
//            .willStartAudioEngine(audioEngine),
//            isPlayoutEnabled: isPlayoutEnabled,
//            isRecordingEnabled: isRecordingEnabled
//        ) {
//            _ = subject.audioDeviceModule(
//                $0,
//                willStartEngine: audioEngine,
//                isPlayoutEnabled: isPlayoutEnabled,
//                isRecordingEnabled: isRecordingEnabled
//            )
//        }
//    }
//
//    func test_willStartEngine_isPlayoutEnabledFalse_isRecordingEnabledTrue_publishesEvent() async throws {
//        let audioEngine = AVAudioEngine()
//        let isPlayoutEnabled = false
//        let isRecordingEnabled = true
//        try await assertEvent(
//            .willStartAudioEngine(audioEngine),
//            isPlayoutEnabled: isPlayoutEnabled,
//            isRecordingEnabled: isRecordingEnabled
//        ) {
//            _ = subject.audioDeviceModule(
//                $0,
//                willStartEngine: audioEngine,
//                isPlayoutEnabled: isPlayoutEnabled,
//                isRecordingEnabled: isRecordingEnabled
//            )
//        }
//    }
//
//    func test_willStartEngine_isPlayoutEnabledTrue_isRecordingEnabledTrue_publishesEvent() async throws {
//        let audioEngine = AVAudioEngine()
//        let isPlayoutEnabled = true
//        let isRecordingEnabled = true
//        try await assertEvent(
//            .willStartAudioEngine(audioEngine),
//            isPlayoutEnabled: isPlayoutEnabled,
//            isRecordingEnabled: isRecordingEnabled
//        ) {
//            _ = subject.audioDeviceModule(
//                $0,
//                willStartEngine: audioEngine,
//                isPlayoutEnabled: isPlayoutEnabled,
//                isRecordingEnabled: isRecordingEnabled
//            )
//        }
//    }
//
//    // MARK: - didStopEngine
//
//    func test_didStopEngine_isPlayoutEnabledFalse_isRecordingEnabledFalse_publishesEvent() async throws {
//        let audioEngine = AVAudioEngine()
//        let isPlayoutEnabled = false
//        let isRecordingEnabled = false
//        try await assertEvent(
//            .didStopAudioEngine(audioEngine),
//            isPlayoutEnabled: isPlayoutEnabled,
//            isRecordingEnabled: isRecordingEnabled
//        ) {
//            _ = subject.audioDeviceModule(
//                $0,
//                didStopEngine: audioEngine,
//                isPlayoutEnabled: isPlayoutEnabled,
//                isRecordingEnabled: isRecordingEnabled
//            )
//        }
//    }
//
//    func test_didStopEngine_isPlayoutEnabledTrue_isRecordingEnabledFalse_publishesEvent() async throws {
//        let audioEngine = AVAudioEngine()
//        let isPlayoutEnabled = true
//        let isRecordingEnabled = false
//        try await assertEvent(
//            .didStopAudioEngine(audioEngine),
//            isPlayoutEnabled: isPlayoutEnabled,
//            isRecordingEnabled: isRecordingEnabled
//        ) {
//            _ = subject.audioDeviceModule(
//                $0,
//                didStopEngine: audioEngine,
//                isPlayoutEnabled: isPlayoutEnabled,
//                isRecordingEnabled: isRecordingEnabled
//            )
//        }
//    }
//
//    func test_didStopEngine_isPlayoutEnabledFalse_isRecordingEnabledTrue_publishesEvent() async throws {
//        let audioEngine = AVAudioEngine()
//        let isPlayoutEnabled = false
//        let isRecordingEnabled = true
//        try await assertEvent(
//            .didStopAudioEngine(audioEngine),
//            isPlayoutEnabled: isPlayoutEnabled,
//            isRecordingEnabled: isRecordingEnabled
//        ) {
//            _ = subject.audioDeviceModule(
//                $0,
//                didStopEngine: audioEngine,
//                isPlayoutEnabled: isPlayoutEnabled,
//                isRecordingEnabled: isRecordingEnabled
//            )
//        }
//    }
//
//    func test_didStopEngine_isPlayoutEnabledTrue_isRecordingEnabledTrue_publishesEvent() async throws {
//        let audioEngine = AVAudioEngine()
//        let isPlayoutEnabled = true
//        let isRecordingEnabled = true
//        try await assertEvent(
//            .didStopAudioEngine(audioEngine),
//            isPlayoutEnabled: isPlayoutEnabled,
//            isRecordingEnabled: isRecordingEnabled
//        ) {
//            _ = subject.audioDeviceModule(
//                $0,
//                didStopEngine: audioEngine,
//                isPlayoutEnabled: isPlayoutEnabled,
//                isRecordingEnabled: isRecordingEnabled
//            )
//        }
//    }
//
//    func test_didStopEngine_uninstallWasCalled() async throws {
//        _ = subject.audioDeviceModule(
//            .init(),
//            didStopEngine: .init(),
//            isPlayoutEnabled: false,
//            isRecordingEnabled: false
//        )
//
//        XCTAssertEqual(audioEngineNodeAdapter.timesCalled(.uninstall), 1)
//        XCTAssertEqual(audioEngineNodeAdapter.recordedInputPayload(Int.self, for: .uninstall)?.first, 0)
//    }
//
//    // MARK: - didDisableEngine
//
//    func test_didDisableEngine_isPlayoutEnabledFalse_isRecordingEnabledFalse_publishesEvent() async throws {
//        let audioEngine = AVAudioEngine()
//        let isPlayoutEnabled = false
//        let isRecordingEnabled = false
//        try await assertEvent(
//            .didDisableAudioEngine(audioEngine),
//            isPlayoutEnabled: isPlayoutEnabled,
//            isRecordingEnabled: isRecordingEnabled
//        ) {
//            _ = subject.audioDeviceModule(
//                $0,
//                didDisableEngine: audioEngine,
//                isPlayoutEnabled: isPlayoutEnabled,
//                isRecordingEnabled: isRecordingEnabled
//            )
//        }
//    }
//
//    func test_didDisableEngine_isPlayoutEnabledTrue_isRecordingEnabledFalse_publishesEvent() async throws {
//        let audioEngine = AVAudioEngine()
//        let isPlayoutEnabled = true
//        let isRecordingEnabled = false
//        try await assertEvent(
//            .didDisableAudioEngine(audioEngine),
//            isPlayoutEnabled: isPlayoutEnabled,
//            isRecordingEnabled: isRecordingEnabled
//        ) {
//            _ = subject.audioDeviceModule(
//                $0,
//                didDisableEngine: audioEngine,
//                isPlayoutEnabled: isPlayoutEnabled,
//                isRecordingEnabled: isRecordingEnabled
//            )
//        }
//    }
//
//    func test_didDisableEngine_isPlayoutEnabledFalse_isRecordingEnabledTrue_publishesEvent() async throws {
//        let audioEngine = AVAudioEngine()
//        let isPlayoutEnabled = false
//        let isRecordingEnabled = true
//        try await assertEvent(
//            .didDisableAudioEngine(audioEngine),
//            isPlayoutEnabled: isPlayoutEnabled,
//            isRecordingEnabled: isRecordingEnabled
//        ) {
//            _ = subject.audioDeviceModule(
//                $0,
//                didDisableEngine: audioEngine,
//                isPlayoutEnabled: isPlayoutEnabled,
//                isRecordingEnabled: isRecordingEnabled
//            )
//        }
//    }
//
//    func test_didDisableEngine_isPlayoutEnabledTrue_isRecordingEnabledTrue_publishesEvent() async throws {
//        let audioEngine = AVAudioEngine()
//        let isPlayoutEnabled = true
//        let isRecordingEnabled = true
//        try await assertEvent(
//            .didDisableAudioEngine(audioEngine),
//            isPlayoutEnabled: isPlayoutEnabled,
//            isRecordingEnabled: isRecordingEnabled
//        ) {
//            _ = subject.audioDeviceModule(
//                $0,
//                didDisableEngine: audioEngine,
//                isPlayoutEnabled: isPlayoutEnabled,
//                isRecordingEnabled: isRecordingEnabled
//            )
//        }
//    }
//
//    func test_didDisableEngine_uninstallWasCalled() async throws {
//        _ = subject.audioDeviceModule(
//            .init(),
//            didDisableEngine: .init(),
//            isPlayoutEnabled: false,
//            isRecordingEnabled: false
//        )
//
//        XCTAssertEqual(audioEngineNodeAdapter.timesCalled(.uninstall), 1)
//        XCTAssertEqual(audioEngineNodeAdapter.recordedInputPayload(Int.self, for: .uninstall)?.first, 0)
//    }
//
//    // MARK: - willReleaseEngine
//
//    func test_willReleaseEngine_publishesEvent() async throws {
//        let audioEngine = AVAudioEngine()
//        try await assertEvent(.willReleaseAudioEngine(audioEngine)) {
//            _ = subject.audioDeviceModule($0, willReleaseEngine: audioEngine)
//        }
//    }
//
//    func test_willReleaseEngine_uninstallWasCalled() async throws {
//        _ = subject.audioDeviceModule(.init(), willReleaseEngine: .init())
//
//        XCTAssertEqual(audioEngineNodeAdapter.timesCalled(.uninstall), 1)
//        XCTAssertEqual(audioEngineNodeAdapter.recordedInputPayload(Int.self, for: .uninstall)?.first, 0)
//    }
//
//    // MARK: - configureInputFromSource
//
//    func test_configureInputFromSource_installWasCalled() async throws {
//        _ = subject.audioDeviceModule(
//            .init(),
//            engine: .init(),
//            configureInputFromSource: nil,
//            toDestination: .init(),
//            format: .init(),
//            context: [:]
//        )
//
//        XCTAssertEqual(audioEngineNodeAdapter.timesCalled(.installInputTap), 1)
//        let rawInput = try XCTUnwrap(
//            audioEngineNodeAdapter.recordedInputPayload(
//                Any.self,
//                for: .installInputTap
//            )?.first
//        )
//        let input = try XCTUnwrap(rawInput as? (Int, UInt32))
//        XCTAssertEqual(input.0, 0)
//        XCTAssertEqual(input.1, 1024)
//    }
//
//    // MARK: - Private Helpers
//
//    private func assertEvent(
//        _ event: AudioDeviceModule.Event,
//        isPlayoutEnabled: Bool? = nil,
//        isRecordingEnabled: Bool? = nil,
//        operation: (RTCAudioDeviceModule) -> Void,
//        file: StaticString = #file,
//        function: StaticString = #function,
//        line: UInt = #line
//    ) async throws {
//        let sinkExpectation = expectation(description: "Sink was called.")
//        let disposableBag = DisposableBag()
//        subject
//            .publisher
//            .filter { $0 == event }
//            .sink { _ in sinkExpectation.fulfill() }
//            .store(in: disposableBag)
//
//        var expectations = [sinkExpectation]
//
//        if let isPlayoutEnabled {
//            let isPlayoutExpectation = expectation(description: "isPlayout:\(isPlayoutEnabled) failed.")
//            subject
//                .isPlayingPublisher
//                .dropFirst()
//                .filter { $0 == isPlayoutEnabled }
//                .sink { _ in isPlayoutExpectation.fulfill() }
//                .store(in: disposableBag)
//            expectations.append(isPlayoutExpectation)
//        }
//
//        if let isRecordingEnabled {
//            let isRecordingEnabledExpectation = expectation(description: "isRecording:\(isRecordingEnabled) failed.")
//            subject
//                .isRecordingPublisher
//                .dropFirst()
//                .filter { $0 == isRecordingEnabled }
//                .sink { _ in isRecordingEnabledExpectation.fulfill() }
//                .store(in: disposableBag)
//            expectations.append(isRecordingEnabledExpectation)
//        }
//
//        operation(.init())
//        await safeFulfillment(of: expectations, file: file, line: line)
//        disposableBag.removeAll()
//    }
// }
