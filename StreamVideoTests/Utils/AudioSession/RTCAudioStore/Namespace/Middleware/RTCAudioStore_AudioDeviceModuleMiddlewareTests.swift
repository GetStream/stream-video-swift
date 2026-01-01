//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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

    // MARK: - setInterrupted

    func test_setInterrupted_whenActiveAndRecordingTrue_nothingHappens() {
        let (module, mock) = makeModule(isRecording: true)
        let state = makeState(
            isActive: true,
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

        XCTAssertEqual(mock.timesCalled(.stopRecording), 0)
        XCTAssertEqual(mock.timesCalled(.initAndStartRecording), 0)
    }

    func test_setInterrupted_whenResumed_restartsRecording() {
        let (module, mock) = makeModule(isRecording: true)
        let state = makeState(
            isActive: true,
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

    // MARK: - setRecording

    func test_setRecording_whenEnabled_startsRecording() {
        let (module, mock) = makeModule(isRecording: false)
        let state = makeState(
            isRecording: false,
            audioDeviceModule: module
        )

        subject.apply(
            state: state,
            action: .setRecording(true),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertEqual(mock.timesCalled(.initAndStartRecording), 1)
    }

    func test_setRecording_whenDisabled_stopsRecording() {
        let (module, mock) = makeModule(isRecording: true)
        let state = makeState(
            isRecording: true,
            audioDeviceModule: module
        )

        subject.apply(
            state: state,
            action: .setRecording(false),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertEqual(mock.timesCalled(.stopRecording), 1)
    }

    // MARK: - setMicrophoneMuted

    func test_setMicrophoneMuted_whenRecordingTrue_updatesModule() {
        let (module, mock) = makeModule(
            isRecording: true,
            isMicrophoneMuted: false
        )
        let state = makeState(
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

        XCTAssertEqual(mock.timesCalled(.initAndStartRecording), 0)
        XCTAssertEqual(mock.timesCalled(.setMicrophoneMuted), 1)
    }

    func test_setMicrophoneMuted_whenRecordingFalse_updatesModule() {
        let (module, mock) = makeModule(
            isRecording: false,
            isMicrophoneMuted: false
        )
        let state = makeState(
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

    func test_setMicrophoneUnMuted_whenRecordingTrue_updatesModule() {
        let (module, mock) = makeModule(
            isRecording: true,
            isMicrophoneMuted: true
        )
        let state = makeState(
            isRecording: true,
            isMicrophoneMuted: true,
            audioDeviceModule: module
        )

        subject.apply(
            state: state,
            action: .setMicrophoneMuted(false),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertEqual(mock.timesCalled(.initAndStartRecording), 0)
        XCTAssertEqual(mock.timesCalled(.setMicrophoneMuted), 1)
    }

    func test_setMicrophoneUnMuted_whenRecordingFalse_updatesModule() {
        let (module, mock) = makeModule(
            isRecording: false,
            isMicrophoneMuted: true
        )
        let state = makeState(
            isRecording: false,
            isMicrophoneMuted: true,
            audioDeviceModule: module
        )

        subject.apply(
            state: state,
            action: .setMicrophoneMuted(false),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertEqual(mock.timesCalled(.initAndStartRecording), 1)
        XCTAssertEqual(mock.timesCalled(.setMicrophoneMuted), 1)
    }

    // MARK: - setAudioDeviceModule

    func test_setAudioDeviceModule_updatesModule() throws {
        let (currentModule, currentMock) = makeModule(
            isRecording: true,
            isMicrophoneMuted: false
        )

        let setRecordingExpectation = expectation(description: "audioDeviceModuleSetRecording called from AudioDeviceModule value.")
        let setMicrophoneMutedExpectation = expectation(description: "setMicrophoneMuted called from AudioDeviceModule value.")
        subject.dispatcher = .init { actions, _, _, _ in
            actions
                .map(\.wrappedValue)
                .forEach { action in
                    switch action {
                    case .audioDeviceModuleSetRecording(true):
                        setRecordingExpectation.fulfill()

                    case .setMicrophoneMuted(false):
                        setMicrophoneMutedExpectation.fulfill()

                    default:
                        break
                    }
                }
        }

        subject.apply(
            state: makeState(),
            action: .setAudioDeviceModule(currentModule),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertEqual(currentMock.timesCalled(.reset), 0)
        XCTAssertEqual(currentMock.timesCalled(.setMuteMode), 1)
        XCTAssertEqual(currentMock.timesCalled(.setRecordingAlwaysPreparedMode), 1)

        wait(for: [setRecordingExpectation, setMicrophoneMutedExpectation], timeout: 1)
    }

    func test_setAudioDeviceModule_replacesModuleAndDispatchesPublishers() throws {
        let (currentModule, currentMock) = makeModule(isRecording: true)
        let (replacementModule, replacementMock) = makeModule(isRecording: false)

        let state = makeState(
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

        XCTAssertEqual(currentMock.timesCalled(.reset), 1)
        XCTAssertEqual(replacementMock.timesCalled(.reset), 0)
        XCTAssertEqual(replacementMock.timesCalled(.setMuteMode), 1)
        XCTAssertEqual(replacementMock.timesCalled(.setRecordingAlwaysPreparedMode), 1)
    }

    // MARK: - setPlayoutPreferred

    func test_setPlayoutPreferred_updatesModule() throws {
        let (module, mock) = makeModule(isRecording: false)

        subject.apply(
            state: makeState(audioDeviceModule: module),
            action: .stereo(.setPlayoutPreferred(true)),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertTrue(mock.prefersStereoPlayout)
    }

    func test_setPlayoutPreferred_false_updatesModule() throws {
        let (module, mock) = makeModule(isRecording: false)

        subject.apply(
            state: makeState(audioDeviceModule: module),
            action: .stereo(.setPlayoutPreferred(false)),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertFalse(mock.prefersStereoPlayout)
    }

    // MARK: - setAudioEnabled

    func test_setAudioEnabled_whenEnabled_updatesModule() throws {
        let (module, mock) = makeModule(isRecording: false)
        let state = makeState(
            isRecording: false,
            audioDeviceModule: module
        )

        subject.apply(
            state: state,
            action: .webRTCAudioSession(.setAudioEnabled(true)),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertEqual(mock.timesCalled(.initAndStartPlayout), 1)
    }

    func test_setAudioEnabled_whenDisabled_updatesModule() throws {
        let (module, mock) = makeModule(isRecording: false, isPlaying: true)
        let state = makeState(
            isRecording: false,
            audioDeviceModule: module
        )

        subject.apply(
            state: state,
            action: .webRTCAudioSession(.setAudioEnabled(false)),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertEqual(mock.timesCalled(.stopPlayout), 1)
    }

    // MARK: - Helpers

    private func makeModule(
        isRecording: Bool,
        isMicrophoneMuted: Bool = false,
        isPlaying: Bool = false
    ) -> (AudioDeviceModule, MockRTCAudioDeviceModule) {
        let source = MockRTCAudioDeviceModule()
        source.stub(for: \.isRecording, with: isRecording)
        source.stub(for: \.isPlaying, with: isPlaying)
        source.stub(for: \.isMicrophoneMuted, with: isMicrophoneMuted)

        let module = AudioDeviceModule(
            source
        )
        return (module, source)
    }

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
