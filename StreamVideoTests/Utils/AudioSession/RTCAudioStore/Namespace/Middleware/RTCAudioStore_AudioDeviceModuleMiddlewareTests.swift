//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
@testable import StreamVideo
import XCTest

final class RTCAudioStore_AudioDeviceModuleMiddlewareTests: XCTestCase, @unchecked Sendable {

    private var recordedSetRecording = false
    private var recordedSetMicrophoneMuted = false
    private var subject: RTCAudioStore.AudioDeviceModuleMiddleware!

    override func setUp() {
        super.setUp()
        subject = .init()
    }

    override func tearDown() {
        subject.dispatcher = nil
        subject = nil
        super.tearDown()
    }

    func test_setInterrupted_whenActiveAndShouldRecordTrue_stopsRecording() {
        let (module, mock) = makeModule(isRecording: true)
        let state = makeState(
            isActive: true,
            shouldRecord: true,
            isRecording: true,
            audioDeviceModule: module
        )

        subject.apply(
            state: state,
            action: .setInterrupted(true),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertEqual(mock.timesCalled(.stopRecording), 1)
        XCTAssertEqual(mock.timesCalled(.initAndStartRecording), 0)
    }

    func test_setInterrupted_whenResumed_restartsRecording() {
        let (module, mock) = makeModule(isRecording: true)
        let state = makeState(
            isActive: true,
            shouldRecord: true,
            isRecording: true,
            audioDeviceModule: module
        )

        subject.apply(
            state: state,
            action: .setInterrupted(false),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertEqual(mock.timesCalled(.stopRecording), 1)
        XCTAssertEqual(mock.timesCalled(.initAndStartRecording), 1)
    }

    func test_setShouldRecord_whenEnabled_startsRecording() {
        let (module, mock) = makeModule(isRecording: false)
        let state = makeState(
            shouldRecord: false,
            isRecording: false,
            audioDeviceModule: module
        )

        subject.apply(
            state: state,
            action: .setShouldRecord(true),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertEqual(mock.timesCalled(.initAndStartRecording), 1)
    }

    func test_setShouldRecord_whenDisabled_stopsRecording() {
        let (module, mock) = makeModule(isRecording: true)
        let state = makeState(
            shouldRecord: true,
            isRecording: true,
            audioDeviceModule: module
        )

        subject.apply(
            state: state,
            action: .setShouldRecord(false),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertEqual(mock.timesCalled(.stopRecording), 1)
    }

    func test_setMicrophoneMuted_whenShouldRecordTrue_updatesModule() {
        let (module, mock) = makeModule(
            isRecording: true,
            isMicrophoneMuted: false
        )
        let state = makeState(
            shouldRecord: true,
            isRecording: true,
            isMicrophoneMuted: false,
            audioDeviceModule: module
        )

        subject.apply(
            state: state,
            action: .setMicrophoneMuted(true),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertEqual(mock.timesCalled(.setMicrophoneMuted), 1)
    }

    func test_setMicrophoneMuted_whenShouldRecordFalse_noInteraction() {
        let (module, mock) = makeModule(
            isRecording: false,
            isMicrophoneMuted: false
        )
        let state = makeState(
            shouldRecord: false,
            audioDeviceModule: module
        )

        subject.apply(
            state: state,
            action: .setMicrophoneMuted(true),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertEqual(mock.timesCalled(.setMicrophoneMuted), 0)
    }

    func test_setAudioDeviceModule_replacesModuleAndDispatchesPublishers() throws {
        let (currentModule, currentMock) = makeModule(isRecording: true)
        let (replacementModule, _) = makeModule(isRecording: false)

        let dispatchExpectation = expectation(description: "Dispatched expected actions")
        dispatchExpectation.expectedFulfillmentCount = 2

        subject.dispatcher = .init { actions, _, _, _ in
            actions
                .map(\.wrappedValue)
                .forEach { action in
                    switch action {
                    case .setRecording(true):
                        guard self.recordedSetRecording == false else { return }
                        self.recordedSetRecording = true
                        dispatchExpectation.fulfill()

                    case .setMicrophoneMuted(true):
                        guard self.recordedSetMicrophoneMuted == false else { return }
                        self.recordedSetMicrophoneMuted = true
                        dispatchExpectation.fulfill()

                    default:
                        break
                    }
                }
        }

        let state = makeState(
            shouldRecord: true,
            isRecording: true,
            isMicrophoneMuted: false,
            audioDeviceModule: currentModule
        )

        subject.apply(
            state: state,
            action: .setAudioDeviceModule(replacementModule),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertEqual(currentMock.timesCalled(.stopRecording), 1)

        // Trigger publisher output.
        let engine = AVAudioEngine()
        _ = replacementModule.audioDeviceModule(
            .init(),
            willEnableEngine: engine,
            isPlayoutEnabled: false,
            isRecordingEnabled: true
        )

        try replacementModule.setMuted(true)

        wait(for: [dispatchExpectation], timeout: 1)
    }

    // MARK: - Helpers

    private func makeModule(
        isRecording: Bool,
        isMicrophoneMuted: Bool = false
    ) -> (AudioDeviceModule, MockRTCAudioDeviceModule) {
        let source = MockRTCAudioDeviceModule()
        source.microphoneMutedSubject.send(isMicrophoneMuted)

        let module = AudioDeviceModule(
            source,
            isRecording: isRecording,
            isMicrophoneMuted: isMicrophoneMuted
        )
        return (module, source)
    }

    private func makeState(
        isActive: Bool = false,
        isInterrupted: Bool = false,
        shouldRecord: Bool = false,
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
            shouldRecord: shouldRecord,
            isRecording: isRecording,
            isMicrophoneMuted: isMicrophoneMuted,
            hasRecordingPermission: hasRecordingPermission,
            audioDeviceModule: audioDeviceModule,
            currentRoute: currentRoute,
            audioSessionConfiguration: audioSessionConfiguration,
            webRTCAudioSessionConfiguration: webRTCAudioSessionConfiguration
        )
    }
}
