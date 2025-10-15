//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import StreamWebRTC
import XCTest

final class RTCAudioSessionReducer_Tests: XCTestCase, @unchecked Sendable {

    // MARK: - Properties

    private lazy var store: MockRTCAudioStore! = .init()
    private lazy var subject: RTCAudioSessionReducer! = .init(
        store: store.audioStore
    )

    // MARK: - Lifecycle

    override func tearDown() {
        subject = nil
        store = nil
        super.tearDown()
    }

    // MARK: - reduce

    // MARK: isActive

    func test_reduce_isActive_differentThanCurrentState_setActiveWasCalled() throws {
        store.session.isActive = false
        _ = try subject.reduce(
            state: .initial,
            action: .audioSession(.isActive(true)),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertEqual(store.session.timesCalled(.setActive), 1)
    }

    func test_reduce_isActive_differentThanCurrentState_updatedStateHasIsActiveCorrectlySet() throws {
        store.session.isActive = false

        let updatedState = try subject.reduce(
            state: .initial,
            action: .audioSession(.isActive(true)),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertTrue(updatedState.isActive)
    }

    // MARK: - isInterrupted

    func test_reduce_isInterrupted_updatedStateWasCorrectlySet() throws {
        var state = RTCAudioStore.State.initial
        state.isInterrupted = false

        let updatedState = try subject.reduce(
            state: state,
            action: .audioSession(.isInterrupted(true)),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertTrue(updatedState.isInterrupted)
    }

    // MARK: isAudioEnabled

    func test_reduce_isAudioEnabled_sessionWasConfiguredCorrectly() throws {
        store.session.isAudioEnabled = false

        _ = try subject.reduce(
            state: .initial,
            action: .audioSession(.isAudioEnabled(true)),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertTrue(store.session.isAudioEnabled)
    }

    func test_reduce_isAudioEnabled_updatedStateHasIsActiveCorrectlySet() throws {
        store.session.isAudioEnabled = false

        let updatedState = try subject.reduce(
            state: .initial,
            action: .audioSession(.isAudioEnabled(true)),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertTrue(updatedState.isAudioEnabled)
    }

    // MARK: useManualAudio

    func test_reduce_useManualAudio_sessionWasConfiguredCorrectly() throws {
        store.session.useManualAudio = false

        _ = try subject.reduce(
            state: .initial,
            action: .audioSession(.useManualAudio(true)),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertTrue(store.session.useManualAudio)
    }

    func test_reduce_useManualAudio_updatedStateHasIsActiveCorrectlySet() throws {
        store.session.useManualAudio = false

        let updatedState = try subject.reduce(
            state: .initial,
            action: .audioSession(.useManualAudio(true)),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertTrue(updatedState.useManualAudio)
    }

    // MARK: - setCategory

    func test_reduce_setCategory_sessionWasConfiguredCorrectly() throws {
        _ = try subject.reduce(
            state: .initial,
            action: .audioSession(
                .setCategory(
                    .playAndRecord,
                    mode: .voiceChat,
                    options: [
                        .allowBluetooth,
                        .mixWithOthers
                    ]
                )
            ),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertEqual(store.session.timesCalled(.setConfiguration), 1)
        let input = try XCTUnwrap(
            store.session.recordedInputPayload(
                RTCAudioSessionConfiguration.self,
                for: .setConfiguration
            )?.first
        )
        XCTAssertEqual(input.category, AVAudioSession.Category.playAndRecord.rawValue)
        XCTAssertEqual(input.mode, AVAudioSession.Mode.voiceChat.rawValue)
        XCTAssertEqual(input.categoryOptions, [.allowBluetooth, .mixWithOthers])
    }

    func test_reduce_setCategory_updatedStateHasIsActiveCorrectlySet() throws {
        var state = RTCAudioStore.State.initial
        state.category = .ambient
        state.mode = .default
        state.options = []

        let updatedState = try subject.reduce(
            state: .initial,
            action: .audioSession(
                .setCategory(
                    .playAndRecord,
                    mode: .voiceChat,
                    options: [
                        .allowBluetooth,
                        .mixWithOthers
                    ]
                )
            ),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertEqual(updatedState.category, .playAndRecord)
        XCTAssertEqual(updatedState.mode, .voiceChat)
        XCTAssertEqual(updatedState.options, [.allowBluetooth, .mixWithOthers])
    }

    // MARK: - setOverrideOutputPort

    func test_reduce_setOverrideOutputPort_sessionWasConfiguredCorrectly() throws {
        _ = try subject.reduce(
            state: .initial,
            action: .audioSession(.setOverrideOutputPort(.speaker)),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertEqual(store.session.timesCalled(.overrideOutputAudioPort), 1)
    }

    func test_reduce_setOverrideOutputPort_updatedStateHasIsActiveCorrectlySet() throws {
        var state = RTCAudioStore.State.initial
        state.overrideOutputAudioPort = .none

        let updatedState = try subject.reduce(
            state: .initial,
            action: .audioSession(.setOverrideOutputPort(.speaker)),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertEqual(updatedState.overrideOutputAudioPort, .speaker)
    }

    // MARK: - setHasRecordingPermission

    func test_reduce_setHasRecordingPermission_updatedStateWasCorrectlySet() throws {
        var state = RTCAudioStore.State.initial
        state.hasRecordingPermission = false

        let updatedState = try subject.reduce(
            state: state,
            action: .audioSession(.setHasRecordingPermission(true)),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertTrue(updatedState.hasRecordingPermission)
    }

    // MARK: - setAVAudioSessionActive

    func test_reduce_setAVAudioSessionActive_isActiveIsTrue_activatesAVSessionIsAudioEnabledIsTrueSetActiveWasCalled() throws {
        var state = RTCAudioStore.State.initial
        state.isAudioEnabled = false
        state.isActive = false

        let updatedState = try subject.reduce(
            state: state,
            action: .audioSession(.setAVAudioSessionActive(true)),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertEqual((store.session.avSession as? MockAVAudioSession)?.timesCalled(.setIsActive), 1)
        XCTAssertTrue(updatedState.isAudioEnabled)
        XCTAssertTrue(updatedState.isActive)
    }

    func test_reduce_setAVAudioSessionActive_isActiveIsFalse_deactivatesAVSessionIsAudioEnabledIsFalseSetActiveWasCalled() throws {
        var state = RTCAudioStore.State.initial
        state.isAudioEnabled = true
        state.isActive = true

        let updatedState = try subject.reduce(
            state: state,
            action: .audioSession(.setAVAudioSessionActive(false)),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertEqual((store.session.avSession as? MockAVAudioSession)?.timesCalled(.setIsActive), 1)
        XCTAssertFalse(updatedState.isAudioEnabled)
        XCTAssertFalse(updatedState.isActive)
    }
}
