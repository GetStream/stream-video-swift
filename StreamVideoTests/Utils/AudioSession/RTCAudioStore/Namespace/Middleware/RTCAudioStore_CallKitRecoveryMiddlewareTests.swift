//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
@testable import StreamVideo
import XCTest

final class RTCAudioStore_CallKitRecoveryMiddlewareTests: XCTestCase, @unchecked Sendable {

    private var receivedActions: Atomic<[RTCAudioStore.StoreAction]>! = .init(wrappedValue: [])
    private var subject: RTCAudioStore.CallKitRecoveryMiddleware!

    override func setUp() {
        super.setUp()
        subject = .init()
        let receivedActions = receivedActions
        subject.dispatcher = .init { actions, _, _, _ in
            receivedActions?.mutate { $0 + actions.map(\.wrappedValue) }
        }
    }

    override func tearDown() {
        subject.dispatcher = nil
        subject = nil
        receivedActions = nil
        super.tearDown()
    }

    // MARK: - apply

    func test_apply_activateWhileRecording_dispatchesRecordingRestart() {
        let (module, _) = makeModule(isRecording: true)
        let state = makeState(
            isRecording: true,
            isMicrophoneMuted: true,
            audioDeviceModule: module
        )

        subject.apply(
            state: state,
            action: .callKit(.activate(AVAudioSession.sharedInstance())),
            file: #file,
            function: #function,
            line: #line
        )

        let actions = receivedActions.wrappedValue
        XCTAssertEqual(actions.count, 3)
        guard
            actions.count == 3,
            case .setRecording(false) = actions[0],
            case .setRecording(true) = actions[1],
            case .setMicrophoneMuted(true) = actions[2]
        else {
            return XCTFail("Unexpected restart actions: \(actions).")
        }
    }

    func test_apply_activateWhileNotRecording_doesNotDispatch() {
        let (module, _) = makeModule(isRecording: false)
        let state = makeState(
            isRecording: false,
            audioDeviceModule: module
        )

        subject.apply(
            state: state,
            action: .callKit(.activate(AVAudioSession.sharedInstance())),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertTrue(receivedActions.wrappedValue.isEmpty)
    }

    func test_apply_activateWhileRecordingWithoutAudioDeviceModule_doesNotDispatch() {
        let state = makeState(
            isRecording: true,
            audioDeviceModule: nil
        )

        subject.apply(
            state: state,
            action: .callKit(.activate(AVAudioSession.sharedInstance())),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertTrue(receivedActions.wrappedValue.isEmpty)
    }

    func test_apply_deactivateWhileRecording_doesNotDispatch() {
        let (module, _) = makeModule(isRecording: true)
        let state = makeState(
            isRecording: true,
            audioDeviceModule: module
        )

        subject.apply(
            state: state,
            action: .callKit(.deactivate(AVAudioSession.sharedInstance())),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertTrue(receivedActions.wrappedValue.isEmpty)
    }

    func test_apply_nonCallKitActionWhileRecording_doesNotDispatch() {
        let (module, _) = makeModule(isRecording: true)
        let state = makeState(
            isRecording: true,
            audioDeviceModule: module
        )

        subject.apply(
            state: state,
            action: .setActive(true),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertTrue(receivedActions.wrappedValue.isEmpty)
    }

    // MARK: - Helpers

    private func makeModule(
        isRecording: Bool,
        isMicrophoneMuted: Bool = false
    ) -> (AudioDeviceModule, MockRTCAudioDeviceModule) {
        let source = MockRTCAudioDeviceModule()
        source.stub(for: \.isRecording, with: isRecording)
        source.stub(for: \.isMicrophoneMuted, with: isMicrophoneMuted)

        let module = AudioDeviceModule(source)
        return (module, source)
    }

    private func makeState(
        isActive: Bool = false,
        isRecording: Bool = false,
        isMicrophoneMuted: Bool = false,
        audioDeviceModule: AudioDeviceModule? = nil
    ) -> RTCAudioStore.StoreState {
        .init(
            isActive: isActive,
            isInterrupted: false,
            isRecording: isRecording,
            isMicrophoneMuted: isMicrophoneMuted,
            isMutedSpeechDetectionEnabled: false,
            hasRecordingPermission: false,
            activeSessionIdentifier: "",
            audioDeviceModule: audioDeviceModule,
            currentRoute: .empty,
            audioSessionConfiguration: .init(
                category: .soloAmbient,
                mode: .default,
                options: [],
                overrideOutputAudioPort: .none
            ),
            webRTCAudioSessionConfiguration: .init(
                isAudioEnabled: false,
                useManualAudio: false,
                prefersNoInterruptionsFromSystemAlerts: false
            ),
            stereoConfiguration: .init(playout: .init(preferred: false, enabled: false))
        )
    }
}
