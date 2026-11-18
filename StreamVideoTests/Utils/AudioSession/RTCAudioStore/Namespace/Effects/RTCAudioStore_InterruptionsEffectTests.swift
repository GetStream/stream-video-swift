//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC
import XCTest

final class RTCAudioStore_InterruptionsEffectTests: XCTestCase, @unchecked Sendable {

    private enum TestError: Error { case stub }

    private var session: RTCAudioSession!
    private var publisher: RTCAudioSessionPublisher!
    private var applicationStateAdapter: MockAppStateAdapter!
    private var subject: RTCAudioStore.InterruptionsEffect!
    private var dispatched: [[StoreActionBox<RTCAudioStore.Namespace.Action>]]!

    override func setUp() {
        super.setUp()
        applicationStateAdapter = .init()
        applicationStateAdapter.makeShared()
        session = RTCAudioSession.sharedInstance()
        publisher = .init(session)
        subject = .init(publisher)
        dispatched = []
    }

    override func tearDown() {
        subject.dispatcher = nil
        subject = nil
        publisher = nil
        session = nil
        applicationStateAdapter.dismante()
        applicationStateAdapter = nil
        dispatched = nil
        super.tearDown()
    }

    func test_didBeginInterruption_dispatchesSetInterruptedTrue() {
        let dispatcherExpectation = expectation(description: "Dispatcher called")
        dispatcherExpectation.assertForOverFulfill = false

        subject.dispatcher = .init { [weak self] actions, _, _, _ in
            self?.dispatched.append(actions)
            dispatcherExpectation.fulfill()
        }

        publisher.audioSessionDidBeginInterruption(session)

        wait(for: [dispatcherExpectation], timeout: 1)

        guard let actions = dispatched.first else {
            return XCTFail("Expected dispatched actions.")
        }

        XCTAssertEqual(actions.count, 1)
        guard case .setInterrupted(true) = actions[0].wrappedValue else {
            return XCTFail("Expected setInterrupted(true).")
        }
    }

    func test_didEndInterruption_isInterrupted_shouldResumeFalse_keepsInterrupted() {
        let dispatcherExpectation = expectation(description: "Dispatcher called")
        dispatcherExpectation.isInverted = true

        subject.dispatcher = .init { [weak self] actions, _, _, _ in
            self?.dispatched.append(actions)
            dispatcherExpectation.fulfill()
        }

        subject.stateProvider = { [weak self] in
            self?.makeState(isInterrupted: true)
        }
        applicationStateAdapter.stubbedState = .background

        publisher.audioSessionDidEndInterruption(session, shouldResumeSession: false)

        wait(for: [dispatcherExpectation], timeout: 0.2)
        XCTAssertTrue(dispatched.isEmpty)
    }

    func test_didEndInterruption_foregroundNonResumingEnd_restartsMutedSpeechCapture() {
        let dispatcherExpectation = expectation(description: "Dispatcher called")
        dispatcherExpectation.assertForOverFulfill = false

        subject.dispatcher = .init { [weak self] actions, _, _, _ in
            self?.dispatched.append(actions)
            dispatcherExpectation.fulfill()
        }

        let module = AudioDeviceModule(MockRTCAudioDeviceModule())
        subject.stateProvider = { [weak self] in
            self?.makeState(
                isInterrupted: true,
                isRecording: true,
                isMicrophoneMuted: true,
                isMutedSpeechDetectionEnabled: true,
                audioDeviceModule: module
            )
        }
        applicationStateAdapter.stubbedState = .foreground

        publisher.audioSessionDidEndInterruption(session, shouldResumeSession: false)

        wait(for: [dispatcherExpectation], timeout: 1)

        guard let actions = dispatched.first else {
            return XCTFail("Expected dispatched actions.")
        }

        XCTAssertEqual(actions.count, 5)
        guard case .setInterrupted(false) = actions[0].wrappedValue else {
            return XCTFail("Expected action[0] setInterrupted(false).")
        }
        guard case .setMutedSpeechDetectionEnabled(false) = actions[1].wrappedValue else {
            return XCTFail("Expected action[1] setMutedSpeechDetectionEnabled(false).")
        }
        guard case .setRecording(false) = actions[2].wrappedValue else {
            return XCTFail("Expected action[2] setRecording(false).")
        }
        guard case .setRecording(true) = actions[3].wrappedValue else {
            return XCTFail("Expected action[3] setRecording(true).")
        }
        guard case .setMutedSpeechDetectionEnabled(true) = actions[4].wrappedValue else {
            return XCTFail("Expected action[4] setMutedSpeechDetectionEnabled(true).")
        }
    }

    func test_didEndInterruption_notInterrupted_shouldResumeTrue_doesNotDispatch() {
        let dispatcherExpectation = expectation(description: "Dispatcher called")
        dispatcherExpectation.isInverted = true

        subject.dispatcher = .init { [weak self] actions, _, _, _ in
            self?.dispatched.append(actions)
            dispatcherExpectation.fulfill()
        }

        let module = AudioDeviceModule(MockRTCAudioDeviceModule())
        subject.stateProvider = { [weak self] in
            self?.makeState(
                isInterrupted: false,
                isRecording: true,
                isMutedSpeechDetectionEnabled: true,
                audioDeviceModule: module
            )
        }

        publisher.audioSessionDidEndInterruption(session, shouldResumeSession: true)

        wait(for: [dispatcherExpectation], timeout: 0.2)
        XCTAssertTrue(dispatched.isEmpty)
    }

    func test_didEndInterruption_notInterrupted_shouldResumeFalse_doesNotDispatch() {
        let dispatcherExpectation = expectation(description: "Dispatcher called")
        dispatcherExpectation.isInverted = true

        subject.dispatcher = .init { [weak self] actions, _, _, _ in
            self?.dispatched.append(actions)
            dispatcherExpectation.fulfill()
        }

        subject.stateProvider = { [weak self] in
            self?.makeState(isInterrupted: false, isRecording: true)
        }

        publisher.audioSessionDidEndInterruption(session, shouldResumeSession: false)

        wait(for: [dispatcherExpectation], timeout: 0.2)
        XCTAssertTrue(dispatched.isEmpty)
    }

    func test_didEndInterruption_shouldResumeTrue_notRecording_clearsInterruptedOnly() {
        let dispatcherExpectation = expectation(description: "Dispatcher called")
        dispatcherExpectation.assertForOverFulfill = false

        subject.dispatcher = .init { [weak self] actions, _, _, _ in
            self?.dispatched.append(actions)
            dispatcherExpectation.fulfill()
        }

        let module = AudioDeviceModule(MockRTCAudioDeviceModule())
        subject.stateProvider = { [weak self] in
            self?.makeState(
                isInterrupted: true,
                isRecording: false,
                isMutedSpeechDetectionEnabled: true,
                audioDeviceModule: module
            )
        }

        publisher.audioSessionDidEndInterruption(session, shouldResumeSession: true)

        wait(for: [dispatcherExpectation], timeout: 1)

        XCTAssertEqual(dispatched.count, 1)
        guard let actions = dispatched.first else {
            return XCTFail("Expected dispatched actions.")
        }

        XCTAssertEqual(actions.count, 1)
        guard case .setInterrupted(false) = actions[0].wrappedValue else {
            return XCTFail("Expected setInterrupted(false).")
        }
    }

    func test_didEndInterruption_secondResumingEnd_doesNotDispatchAgain() {
        final class StateBox: @unchecked Sendable {
            var state: RTCAudioStore.StoreState
            init(_ state: RTCAudioStore.StoreState) { self.state = state }
        }

        let module = AudioDeviceModule(MockRTCAudioDeviceModule())
        let box = StateBox(
            makeState(
                isInterrupted: true,
                isRecording: true,
                audioDeviceModule: module
            )
        )
        let resume = expectation(description: "Dispatcher called")
        resume.assertForOverFulfill = false
        subject.dispatcher = .init { [weak self] actions, _, _, _ in
            self?.dispatched.append(actions)
            for action in actions {
                if case .setInterrupted(let value) = action.wrappedValue {
                    box.state.isInterrupted = value
                }
            }
            resume.fulfill()
        }
        subject.stateProvider = { box.state }

        publisher.audioSessionDidEndInterruption(session, shouldResumeSession: true)
        publisher.audioSessionDidEndInterruption(session, shouldResumeSession: true)

        wait(for: [resume], timeout: 1)

        XCTAssertEqual(dispatched.count, 1)
        guard let actions = dispatched.first else {
            return XCTFail("Expected one recovery batch.")
        }

        XCTAssertEqual(actions.count, 3)
        guard case .setInterrupted(false) = actions[0].wrappedValue else {
            return XCTFail("Expected action[0] setInterrupted(false).")
        }
        guard case .setRecording(false) = actions[1].wrappedValue else {
            return XCTFail("Expected action[1] setRecording(false).")
        }
        guard case .setRecording(true) = actions[2].wrappedValue else {
            return XCTFail("Expected action[2] setRecording(true).")
        }
    }

    func test_didEndInterruption_isInterrupted_shouldResumeTrue_withoutAudioDeviceModule_dispatchesSetInterruptedFalse() {
        let dispatcherExpectation = expectation(description: "Dispatcher called")
        dispatcherExpectation.assertForOverFulfill = false

        subject.dispatcher = .init { [weak self] actions, _, _, _ in
            self?.dispatched.append(actions)
            dispatcherExpectation.fulfill()
        }

        subject.stateProvider = { [weak self] in
            self?.makeState(
                isInterrupted: true,
                audioDeviceModule: nil
            )
        }

        publisher.audioSessionDidEndInterruption(session, shouldResumeSession: true)

        wait(for: [dispatcherExpectation], timeout: 1)

        guard let actions = dispatched.first else {
            return XCTFail("Expected dispatched actions.")
        }

        XCTAssertEqual(actions.count, 1)
        guard case .setInterrupted(false) = actions[0].wrappedValue else {
            return XCTFail("Expected setInterrupted(false).")
        }
    }

    func test_didEndInterruption_isInterrupted_shouldResumeTrue_withAudioDeviceModule_dispatchesRecoveryActions() {
        let dispatcherExpectation = expectation(description: "Dispatcher called")
        dispatcherExpectation.assertForOverFulfill = false

        subject.dispatcher = .init { [weak self] actions, _, _, _ in
            self?.dispatched.append(actions)
            dispatcherExpectation.fulfill()
        }

        let module = AudioDeviceModule(MockRTCAudioDeviceModule())
        subject.stateProvider = { [weak self] in
            self?.makeState(
                isInterrupted: true,
                isRecording: true,
                isMicrophoneMuted: true,
                audioDeviceModule: module
            )
        }

        publisher.audioSessionDidEndInterruption(session, shouldResumeSession: true)

        wait(for: [dispatcherExpectation], timeout: 1)

        guard let actions = dispatched.first else {
            return XCTFail("Expected dispatched actions.")
        }

        XCTAssertEqual(actions.count, 3)
        guard case .setInterrupted(false) = actions[0].wrappedValue else {
            return XCTFail("Expected action[0] setInterrupted(false).")
        }
        guard case .setRecording(false) = actions[1].wrappedValue else {
            return XCTFail("Expected action[1] setRecording(false).")
        }
        guard case .setRecording(true) = actions[2].wrappedValue else {
            return XCTFail("Expected action[2] setRecording(true).")
        }
    }

    func test_didEndInterruption_shouldResumeTrue_recordingAndMutedSpeechDetection_togglesPersistentModeAroundRestart() {
        let dispatcherExpectation = expectation(description: "Dispatcher called")
        dispatcherExpectation.assertForOverFulfill = false

        subject.dispatcher = .init { [weak self] actions, _, _, _ in
            self?.dispatched.append(actions)
            dispatcherExpectation.fulfill()
        }

        let module = AudioDeviceModule(MockRTCAudioDeviceModule())
        subject.stateProvider = { [weak self] in
            self?.makeState(
                isInterrupted: true,
                isRecording: true,
                isMicrophoneMuted: true,
                isMutedSpeechDetectionEnabled: true,
                audioDeviceModule: module
            )
        }

        publisher.audioSessionDidEndInterruption(session, shouldResumeSession: true)

        wait(for: [dispatcherExpectation], timeout: 1)

        guard let actions = dispatched.first else {
            return XCTFail("Expected dispatched actions.")
        }

        XCTAssertEqual(actions.count, 5)
        guard case .setInterrupted(false) = actions[0].wrappedValue else {
            return XCTFail("Expected action[0] setInterrupted(false).")
        }
        guard case .setMutedSpeechDetectionEnabled(false) = actions[1].wrappedValue else {
            return XCTFail("Expected action[1] setMutedSpeechDetectionEnabled(false).")
        }
        guard case .setRecording(false) = actions[2].wrappedValue else {
            return XCTFail("Expected action[2] setRecording(false).")
        }
        guard case .setRecording(true) = actions[3].wrappedValue else {
            return XCTFail("Expected action[3] setRecording(true).")
        }
        guard case .setMutedSpeechDetectionEnabled(true) = actions[4].wrappedValue else {
            return XCTFail("Expected action[4] setMutedSpeechDetectionEnabled(true).")
        }
    }

    func test_didEndInterruption_nonResumingEndThenResumingEnd_restartsMutedSpeechCapture() {
        final class StateBox: @unchecked Sendable {
            var state: RTCAudioStore.StoreState
            init(_ state: RTCAudioStore.StoreState) { self.state = state }
        }

        let module = AudioDeviceModule(MockRTCAudioDeviceModule())
        let box = StateBox(
            makeState(
                isInterrupted: true,
                isRecording: true,
                isMicrophoneMuted: true,
                isMutedSpeechDetectionEnabled: true,
                audioDeviceModule: module
            )
        )
        let resume = expectation(description: "Dispatcher called")
        subject.dispatcher = .init { [weak self] actions, _, _, _ in
            self?.dispatched.append(actions)
            for action in actions {
                if case .setInterrupted(let value) = action.wrappedValue {
                    box.state.isInterrupted = value
                }
            }
            resume.fulfill()
        }
        subject.stateProvider = { box.state }
        applicationStateAdapter.stubbedState = .background

        publisher.audioSessionDidEndInterruption(session, shouldResumeSession: false)
        publisher.audioSessionDidEndInterruption(session, shouldResumeSession: true)

        wait(for: [resume], timeout: 1)

        XCTAssertEqual(dispatched.count, 1)
        guard let actions = dispatched.first else {
            return XCTFail("Expected the resumable end to recover capture.")
        }

        XCTAssertEqual(actions.count, 5)
        guard case .setInterrupted(false) = actions[0].wrappedValue else {
            return XCTFail("Expected action[0] setInterrupted(false).")
        }
        guard case .setMutedSpeechDetectionEnabled(false) = actions[1].wrappedValue else {
            return XCTFail("Expected action[1] setMutedSpeechDetectionEnabled(false).")
        }
        guard case .setRecording(false) = actions[2].wrappedValue else {
            return XCTFail("Expected action[2] setRecording(false).")
        }
        guard case .setRecording(true) = actions[3].wrappedValue else {
            return XCTFail("Expected action[3] setRecording(true).")
        }
        guard case .setMutedSpeechDetectionEnabled(true) = actions[4].wrappedValue else {
            return XCTFail("Expected action[4] setMutedSpeechDetectionEnabled(true).")
        }
    }

    // MARK: - Helpers

    private func makeState(
        isActive: Bool = false,
        isInterrupted: Bool = false,
        isRecording: Bool = false,
        isMicrophoneMuted: Bool = false,
        isMutedSpeechDetectionEnabled: Bool = false,
        hasRecordingPermission: Bool = false,
        activeSessionIdentifier: String = "",
        audioDeviceModule: AudioDeviceModule? = nil,
        currentRoute: RTCAudioStore.StoreState.AudioRoute = .empty,
        audioSessionConfiguration: RTCAudioStore.StoreState.AVAudioSessionConfiguration = .init(
            category: .soloAmbient,
            mode: .default,
            options: [],
            overrideOutputAudioPort: .none
        ),
        webRTCAudioSessionConfiguration: RTCAudioStore.StoreState.WebRTCAudioSessionConfiguration = .init(
            isAudioEnabled: false,
            useManualAudio: false,
            prefersNoInterruptionsFromSystemAlerts: false
        )
    ) -> RTCAudioStore.StoreState {
        .init(
            isActive: isActive,
            isInterrupted: isInterrupted,
            isRecording: isRecording,
            isMicrophoneMuted: isMicrophoneMuted,
            isMutedSpeechDetectionEnabled: isMutedSpeechDetectionEnabled,
            hasRecordingPermission: hasRecordingPermission,
            activeSessionIdentifier: activeSessionIdentifier,
            audioDeviceModule: audioDeviceModule,
            currentRoute: currentRoute,
            audioSessionConfiguration: audioSessionConfiguration,
            webRTCAudioSessionConfiguration: webRTCAudioSessionConfiguration,
            stereoConfiguration: .init(playout: .init(preferred: false, enabled: false))
        )
    }
}
