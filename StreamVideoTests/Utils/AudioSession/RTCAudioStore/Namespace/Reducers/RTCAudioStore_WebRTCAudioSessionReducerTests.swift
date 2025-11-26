//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class RTCAudioStore_WebRTCAudioSessionReducerTests: XCTestCase, @unchecked Sendable {

    private enum TestError: Error { case stub }

    private var session: MockAudioSession!
    private var subject: RTCAudioStore.Namespace.WebRTCAudioSessionReducer!

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

    func test_reduce_nonWebRTCAudioSessionAction_returnsUnchangedState() async throws {
        let state = makeState()

        let result = try await subject.reduce(
            state: state,
            action: .setActive(true),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertEqual(result, state)
        XCTAssertFalse(session.isAudioEnabled)
        XCTAssertFalse(session.useManualAudio)
    }

    func test_reduce_setAudioEnabled_updatesSessionAndState() async throws {
        session.isAudioEnabled = false
        let state = makeState(
            webRTCAudioSessionConfiguration: .init(
                isAudioEnabled: false,
                useManualAudio: false,
                prefersNoInterruptionsFromSystemAlerts: false
            )
        )

        let result = try await subject.reduce(
            state: state,
            action: .webRTCAudioSession(.setAudioEnabled(true)),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertTrue(session.isAudioEnabled)
        XCTAssertTrue(result.webRTCAudioSessionConfiguration.isAudioEnabled)
    }

    func test_reduce_setUseManualAudio_updatesSessionAndState() async throws {
        session.useManualAudio = false
        let state = makeState(
            webRTCAudioSessionConfiguration: .init(
                isAudioEnabled: true,
                useManualAudio: false,
                prefersNoInterruptionsFromSystemAlerts: false
            )
        )

        let result = try await subject.reduce(
            state: state,
            action: .webRTCAudioSession(.setUseManualAudio(true)),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertTrue(session.useManualAudio)
        XCTAssertTrue(result.webRTCAudioSessionConfiguration.useManualAudio)
    }

    func test_reduce_setPrefersNoInterruptions_updatesSessionAndState() async throws {
        guard #available(iOS 14.5, macOS 11.3, *) else {
            throw XCTSkip("setPrefersNoInterruptionsFromSystemAlerts available from iOS 14.5 / macOS 11.3.")
        }

        let state = makeState(
            webRTCAudioSessionConfiguration: .init(
                isAudioEnabled: true,
                useManualAudio: true,
                prefersNoInterruptionsFromSystemAlerts: false
            )
        )

        let result = try await subject.reduce(
            state: state,
            action: .webRTCAudioSession(.setPrefersNoInterruptionsFromSystemAlerts(true)),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertTrue(session.prefersNoInterruptionsFromSystemAlerts)
        XCTAssertTrue(result.webRTCAudioSessionConfiguration.prefersNoInterruptionsFromSystemAlerts)
    }

    func test_reduce_setPrefersNoInterruptions_propagatesError() async throws {
        guard #available(iOS 14.5, macOS 11.3, *) else {
            throw XCTSkip("setPrefersNoInterruptionsFromSystemAlerts available from iOS 14.5 / macOS 11.3.")
        }

        session.stub(
            for: .setPrefersNoInterruptionsFromSystemAlerts,
            with: TestError.stub
        )
        let state = makeState()

        do {
            _ = try await subject.reduce(
                state: state,
                action: .webRTCAudioSession(.setPrefersNoInterruptionsFromSystemAlerts(true)),
                file: #file,
                function: #function,
                line: #line
            )
            XCTFail()
        } catch {
            XCTAssertTrue(error is TestError)
            let calls = self.session.recordedInputPayload(
                Bool.self,
                for: .setPrefersNoInterruptionsFromSystemAlerts
            ) ?? []
            XCTAssertEqual(calls, [true])
            XCTAssertFalse(self.session.prefersNoInterruptionsFromSystemAlerts)
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
