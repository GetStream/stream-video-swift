//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC
import XCTest

final class RTCAudioStore_InterruptionsEffectTests: XCTestCase, @unchecked Sendable {

    private enum TestError: Error { case stub }

    private var session: RTCAudioSession!
    private var publisher: RTCAudioSessionPublisher!
    private var subject: RTCAudioStore.InterruptionsEffect!
    private var dispatched: [[StoreActionBox<RTCAudioStore.Namespace.Action>]]!

    override func setUp() {
        super.setUp()
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

    func test_didEndInterruption_shouldResumeFalse_dispatchesSetInterruptedFalseOnly() {
        let dispatcherExpectation = expectation(description: "Dispatcher called")
        dispatcherExpectation.assertForOverFulfill = false

        subject.dispatcher = .init { [weak self] actions, _, _, _ in
            self?.dispatched.append(actions)
            dispatcherExpectation.fulfill()
        }

        publisher.audioSessionDidEndInterruption(session, shouldResumeSession: false)

        wait(for: [dispatcherExpectation], timeout: 1)

        guard let actions = dispatched.first else {
            return XCTFail("Expected dispatched actions.")
        }

        XCTAssertEqual(actions.count, 1)
        guard case .setInterrupted(false) = actions[0].wrappedValue else {
            return XCTFail("Expected setInterrupted(false).")
        }
    }

    func test_didEndInterruption_shouldResumeTrue_withoutAudioDeviceModule_dispatchesSetInterruptedFalse() {
        let dispatcherExpectation = expectation(description: "Dispatcher called")
        dispatcherExpectation.assertForOverFulfill = false

        subject.dispatcher = .init { [weak self] actions, _, _, _ in
            self?.dispatched.append(actions)
            dispatcherExpectation.fulfill()
        }

        subject.stateProvider = { [weak self] in
            self?.makeState(audioDeviceModule: nil)
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

    func test_didEndInterruption_shouldResumeTrue_withAudioDeviceModule_dispatchesRecoveryActions() {
        let dispatcherExpectation = expectation(description: "Dispatcher called")
        dispatcherExpectation.assertForOverFulfill = false

        subject.dispatcher = .init { [weak self] actions, _, _, _ in
            self?.dispatched.append(actions)
            dispatcherExpectation.fulfill()
        }

        let module = AudioDeviceModule(MockRTCAudioDeviceModule())
        subject.stateProvider = { [weak self] in
            self?.makeState(
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

        XCTAssertEqual(actions.count, 4)
        guard case .setInterrupted(false) = actions[0].wrappedValue else {
            return XCTFail("Expected action[0] setInterrupted(false).")
        }
        guard case .setRecording(false) = actions[1].wrappedValue else {
            return XCTFail("Expected action[1] setRecording(false).")
        }
        guard case .setRecording(true) = actions[2].wrappedValue else {
            return XCTFail("Expected action[2] setRecording(true).")
        }
        guard case .setMicrophoneMuted(true) = actions[3].wrappedValue else {
            return XCTFail("Expected action[3] setMicrophoneMuted(true).")
        }
    }

    // MARK: - Helpers

    private func makeState(
        isActive: Bool = false,
        isInterrupted: Bool = false,
        isRecording: Bool = false,
        isMicrophoneMuted: Bool = false,
        hasRecordingPermission: Bool = false,
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
            hasRecordingPermission: hasRecordingPermission,
            audioDeviceModule: audioDeviceModule,
            currentRoute: currentRoute,
            audioSessionConfiguration: audioSessionConfiguration,
            webRTCAudioSessionConfiguration: webRTCAudioSessionConfiguration,
            stereoConfiguration: .init(playout: .init(preferred: false, enabled: false))
        )
    }
}
