//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
@testable import StreamVideo
import XCTest

final class RTCAudioStore_AVAudioSessionReducerTests: XCTestCase, @unchecked Sendable {

    private enum TestError: Error { case stub }

    private var session: MockAudioSession!
    private var subject: RTCAudioStore.Namespace.AVAudioSessionReducer!

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

    func test_reduce_nonAVAudioSessionAction_returnsUnchangedState() async throws {
        let state = makeState()

        let result = try await subject.reduce(
            state: state,
            action: .setActive(true),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertEqual(result, state)
        XCTAssertEqual(session.timesCalled(.setConfiguration), 0)
    }

    func test_reduce_setCategory_updatesSessionAndState() async throws {
        let state = makeState(
            category: .soloAmbient,
            mode: .default,
            options: []
        )
        session.category = AVAudioSession.Category.soloAmbient.rawValue

        let result = try await subject.reduce(
            state: state,
            action: .avAudioSession(.setCategory(.playback)),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertEqual(result.audioSessionConfiguration.category, .playback)
        XCTAssertEqual(session.timesCalled(.setConfiguration), 1)
    }

    func test_reduce_setCategory_sameValue_skipsSessionWork() async throws {
        let state = makeState(
            category: .playback,
            mode: .default,
            options: []
        )
        session.category = AVAudioSession.Category.playback.rawValue

        let result = try await subject.reduce(
            state: state,
            action: .avAudioSession(.setCategory(.playback)),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertEqual(result.audioSessionConfiguration.category, .playback)
        XCTAssertEqual(session.timesCalled(.setConfiguration), 0)
    }

    func test_reduce_setMode_invalidConfiguration_throws() async {
        let state = makeState(
            category: .playback,
            mode: .default,
            options: []
        )

        do {
            _ = try await subject.reduce(
                state: state,
                action: .avAudioSession(.setMode(.voiceChat)),
                file: #file,
                function: #function,
                line: #line
            )
            XCTFail()
        } catch {
            XCTAssertTrue(error is ClientError)
            XCTAssertEqual(self.session.timesCalled(.setConfiguration), 0)
        }
    }

    func test_reduce_setCategoryOptions_activeSession_restartsAudioSession() async throws {
        let state = makeState(
            category: .playAndRecord,
            mode: .voiceChat,
            options: [.allowBluetoothHFP]
        )
        session.category = AVAudioSession.Category.playAndRecord.rawValue
        session.mode = AVAudioSession.Mode.voiceChat.rawValue
        session.categoryOptions = [.allowBluetoothHFP]
        session.isActive = true

        let result = try await subject.reduce(
            state: state,
            action: .avAudioSession(.setCategoryOptions([.allowBluetoothHFP, .defaultToSpeaker])),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertTrue(result.audioSessionConfiguration.options.contains(.defaultToSpeaker))
        let calls = session.recordedInputPayload(Bool.self, for: .setActive) ?? []
        XCTAssertEqual(calls, [false, true])
        XCTAssertEqual(session.timesCalled(.setConfiguration), 1)
    }

    func test_reduce_setOverrideOutputAudioPort_playAndRecord_forwardsToSession() async throws {
        let state = makeState(
            category: .playAndRecord,
            mode: .voiceChat,
            options: []
        )
        session.category = AVAudioSession.Category.playAndRecord.rawValue

        let result = try await subject.reduce(
            state: state,
            action: .avAudioSession(.setOverrideOutputAudioPort(.speaker)),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertEqual(result.audioSessionConfiguration.overrideOutputAudioPort, .speaker)
        let recorded = session.recordedInputPayload(
            AVAudioSession.PortOverride.self,
            for: .overrideOutputAudioPort
        ) ?? []
        XCTAssertEqual(recorded, [.speaker])
    }

    func test_reduce_setOverrideOutputAudioPort_updatesDefaultToSpeakerOption() async throws {
        let state = makeState(
            category: .playback,
            mode: .default,
            options: []
        )
        session.category = AVAudioSession.Category.playback.rawValue
        session.categoryOptions = []

        let result = try await subject.reduce(
            state: state,
            action: .avAudioSession(.setOverrideOutputAudioPort(.speaker)),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertTrue(result.audioSessionConfiguration.options.contains(.defaultToSpeaker))
        XCTAssertEqual(session.timesCalled(.setConfiguration), 1)
    }

    func test_reduce_setOverrideOutputAudioPort_disablingSpeakerRemovesOption() async throws {
        let state = makeState(
            category: .playback,
            mode: .default,
            options: [.defaultToSpeaker]
        )
        session.category = AVAudioSession.Category.playback.rawValue
        session.categoryOptions = [.defaultToSpeaker]

        let result = try await subject.reduce(
            state: state,
            action: .avAudioSession(.setOverrideOutputAudioPort(.none)),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertFalse(result.audioSessionConfiguration.options.contains(.defaultToSpeaker))
        XCTAssertEqual(session.timesCalled(.setConfiguration), 1)
    }

    func test_reduce_systemSetCategory_updatesStateWithoutCallingSession() async throws {
        let state = makeState(
            category: .playback,
            mode: .default,
            options: []
        )

        let result = try await subject.reduce(
            state: state,
            action: .avAudioSession(.systemSetCategory(.playAndRecord)),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertEqual(result.audioSessionConfiguration.category, .playAndRecord)
        XCTAssertEqual(session.timesCalled(.setConfiguration), 0)
    }

    func test_reduce_setCurrentRoute_updatesOverridePort() async throws {
        let state = makeState(overrideOutput: .none)
        let speakerRoute = RTCAudioStore.StoreState.AudioRoute(
            inputs: [],
            outputs: [
                .init(
                    type: .unique,
                    name: .unique,
                    id: .unique,
                    isExternal: false,
                    isSpeaker: true,
                    isReceiver: false,
                    channels: 2
                )
            ]
        )

        let result = try await subject.reduce(
            state: state,
            action: .setCurrentRoute(speakerRoute),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertEqual(result.audioSessionConfiguration.overrideOutputAudioPort, .speaker)
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
        category: AVAudioSession.Category = .soloAmbient,
        mode: AVAudioSession.Mode = .default,
        options: AVAudioSession.CategoryOptions = [],
        overrideOutput: AVAudioSession.PortOverride = .none,
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
            audioSessionConfiguration: .init(
                category: category,
                mode: mode,
                options: options,
                overrideOutputAudioPort: overrideOutput
            ),
            webRTCAudioSessionConfiguration: webRTCAudioSessionConfiguration,
            stereoConfiguration: .init(playout: .init(preferred: false, enabled: false))
        )
    }
}
