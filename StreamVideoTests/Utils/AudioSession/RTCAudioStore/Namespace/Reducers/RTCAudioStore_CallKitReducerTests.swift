//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
@testable import StreamVideo
import XCTest

final class RTCAudioStore_CallKitReducerTests: XCTestCase, @unchecked Sendable {

    private var session: MockAudioSession!
    private var subject: RTCAudioStore.Namespace.CallKitReducer!

    override func setUp() {
        super.setUp()
        session = .init()
        subject = .init(session)
    }

    override func tearDown() {
        subject = nil
        session = nil
        super.tearDown()
    }

    func test_reduce_nonCallKitAction_returnsUnchangedState() async throws {
        let state = makeState()

        let result = try await subject.reduce(
            state: state,
            action: .setActive(true),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertEqual(result, state)
        XCTAssertEqual(session.timesCalled(.audioSessionDidActivate), 0)
        XCTAssertEqual(session.timesCalled(.audioSessionDidDeactivate), 0)
    }

    func test_reduce_activate_forwardsToSessionAndUpdatesState() async throws {
        let state = makeState(isActive: false)
        session.isActive = true
        let avSession = AVAudioSession.sharedInstance()

        let result = try await subject.reduce(
            state: state,
            action: .callKit(.activate(avSession)),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertEqual(session.timesCalled(.audioSessionDidActivate), 1)
        let recorded = session.recordedInputPayload(
            AVAudioSession.self,
            for: .audioSessionDidActivate
        ) ?? []
        XCTAssertTrue(recorded.first === avSession)
        XCTAssertTrue(result.isActive)
    }

    func test_reduce_deactivate_forwardsToSessionAndUpdatesState() async throws {
        let state = makeState(isActive: true)
        session.isActive = false
        let avSession = AVAudioSession.sharedInstance()

        let result = try await subject.reduce(
            state: state,
            action: .callKit(.deactivate(avSession)),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertEqual(session.timesCalled(.audioSessionDidDeactivate), 1)
        let recorded = session.recordedInputPayload(
            AVAudioSession.self,
            for: .audioSessionDidDeactivate
        ) ?? []
        XCTAssertTrue(recorded.first === avSession)
        XCTAssertFalse(result.isActive)
    }

    // MARK: - Helpers

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
