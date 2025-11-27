//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class RTCAudioStore_DefaultReducerTests: XCTestCase, @unchecked Sendable {

    private enum TestError: Error { case stub }

    private var session: MockAudioSession!
    private var subject: RTCAudioStore.Namespace.DefaultReducer!

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

    // MARK: - setActive

    func test_reduce_setActive_whenStateDiffers_updatesSessionAndState() async throws {
        session.isActive = false
        let state = makeState(isActive: false)

        let result = try await subject.reduce(
            state: state,
            action: .setActive(true),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertTrue(result.isActive)
        let activeCalls = session.recordedInputPayload(Bool.self, for: .setActive) ?? []
        XCTAssertEqual(activeCalls, [true])

        guard let avSession = session.avSession as? MockAVAudioSession else {
            return XCTFail("Expected MockAVAudioSession.")
        }
        let setIsActiveCalls = avSession.recordedInputPayload(Bool.self, for: .setIsActive) ?? []
        XCTAssertEqual(setIsActiveCalls, [true])
    }

    func test_reduce_setActive_whenStateMatches_skipsSessionWork() async throws {
        session.isActive = false
        let state = makeState(isActive: false)

        let result = try await subject.reduce(
            state: state,
            action: .setActive(false),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertFalse(result.isActive)
        XCTAssertTrue((session.recordedInputPayload(Bool.self, for: .setActive) ?? []).isEmpty)

        guard let avSession = session.avSession as? MockAVAudioSession else {
            return XCTFail("Expected MockAVAudioSession.")
        }
        XCTAssertTrue((avSession.recordedInputPayload(Bool.self, for: .setIsActive) ?? []).isEmpty)
    }

    func test_reduce_setActive_whenSessionThrows_propagatesError() async {
        session.isActive = false
        let state = makeState(isActive: false)

        guard let avSession = session.avSession as? MockAVAudioSession else {
            return XCTFail("Expected MockAVAudioSession.")
        }
        avSession.stub(for: .setIsActive, with: TestError.stub)

        do {
            _ = try await subject.reduce(
                state: state,
                action: .setActive(true),
                file: #file,
                function: #function,
                line: #line
            )
            XCTFail()
        } catch {
            XCTAssertTrue(error is TestError)
            let calls = self.session.recordedInputPayload(Bool.self, for: .setActive) ?? []
            XCTAssertEqual(calls, [true])
        }
    }

    func test_reduce_setActive_updatesAudioDeviceModulePlayout() async throws {
        session.isActive = false
        let (audioDeviceModule, mockModule) = makeAudioDeviceModule()
        mockModule.stub(for: \.isPlayoutInitialized, with: false)
        let state = makeState(
            isActive: false,
            audioDeviceModule: audioDeviceModule
        )

        _ = try await subject.reduce(
            state: state,
            action: .setActive(true),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertEqual(mockModule.timesCalled(.initAndStartPlayout), 1)
    }

    // MARK: - setAudioDeviceModule

    func test_reduce_setAudioDeviceModule_nil_resetsRecordingFlags() async throws {
        let module = AudioDeviceModule(MockRTCAudioDeviceModule())
        let state = makeState(
            isRecording: true,
            isMicrophoneMuted: true,
            audioDeviceModule: module
        )

        let result = try await subject.reduce(
            state: state,
            action: .setAudioDeviceModule(nil),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertNil(result.audioDeviceModule)
        XCTAssertFalse(result.isRecording)
        XCTAssertTrue(result.isMicrophoneMuted)
    }

    func test_reduce_setAudioDeviceModule_nonNil_preservesRecordingFlags() async throws {
        let currentModule = AudioDeviceModule(MockRTCAudioDeviceModule())
        let replacement = AudioDeviceModule(MockRTCAudioDeviceModule())
        let state = makeState(
            isRecording: true,
            isMicrophoneMuted: true,
            audioDeviceModule: currentModule
        )

        let result = try await subject.reduce(
            state: state,
            action: .setAudioDeviceModule(replacement),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertTrue(result.audioDeviceModule === replacement)
        XCTAssertTrue(result.isRecording)
        XCTAssertTrue(result.isMicrophoneMuted)
    }

    func test_reduce_setAudioDeviceModule_nil_resetsStereoConfiguration() async throws {
        let module = AudioDeviceModule(MockRTCAudioDeviceModule())
        let stereoConfiguration = RTCAudioStore.StoreState.StereoConfiguration(
            playout: .init(preferred: true, enabled: true)
        )
        let state = makeState(
            audioDeviceModule: module,
            stereoConfiguration: stereoConfiguration
        )

        let result = try await subject.reduce(
            state: state,
            action: .setAudioDeviceModule(nil),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertFalse(result.stereoConfiguration.playout.preferred)
        XCTAssertFalse(result.stereoConfiguration.playout.enabled)
    }

    // MARK: - Passthrough actions

    func test_reduce_avAudioSessionAction_returnsUnchangedState() async throws {
        let state = makeState()

        let result = try await subject.reduce(
            state: state,
            action: .avAudioSession(.setMode(.voiceChat)),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertEqual(result, state)
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
        ),
        stereoConfiguration: RTCAudioStore.StoreState.StereoConfiguration = .init(
            playout: .init(
                preferred: false,
                enabled: false
            )
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
            stereoConfiguration: stereoConfiguration
        )
    }

    private func makeAudioDeviceModule() -> (AudioDeviceModule, MockRTCAudioDeviceModule) {
        let mock = MockRTCAudioDeviceModule()
        let module = AudioDeviceModule(mock)
        return (module, mock)
    }
}
