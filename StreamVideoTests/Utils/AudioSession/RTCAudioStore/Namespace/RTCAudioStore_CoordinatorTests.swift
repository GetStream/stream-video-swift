//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
@testable import StreamVideo
import XCTest

final class RTCAudioStore_CoordinatorTests: XCTestCase, @unchecked Sendable {

    private var subject: RTCAudioStore.Coordinator! = .init()

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func test_setActive_sameValue_returnsFalse() {
        let state = makeState(isActive: true)

        XCTAssertFalse(
            subject.shouldExecute(
                action: .setActive(true),
                state: state
            )
        )
    }

    func test_setActive_differentValue_returnsTrue() {
        let state = makeState(isActive: false)

        XCTAssertTrue(
            subject.shouldExecute(
                action: .setActive(true),
                state: state
            )
        )
    }

    func test_setAudioDeviceModule_sameInstance_returnsFalse() {
        let module = AudioDeviceModule(MockRTCAudioDeviceModule())
        let state = makeState(audioDeviceModule: module)

        XCTAssertFalse(
            subject.shouldExecute(
                action: .setAudioDeviceModule(module),
                state: state
            )
        )
    }

    func test_setAudioDeviceModule_differentInstance_returnsTrue() {
        let state = makeState(
            audioDeviceModule: AudioDeviceModule(
                MockRTCAudioDeviceModule()
            )
        )
        let replacement = AudioDeviceModule(MockRTCAudioDeviceModule())

        XCTAssertTrue(
            subject.shouldExecute(
                action: .setAudioDeviceModule(replacement),
                state: state
            )
        )
    }

    func test_setCurrentRoute_sameValue_returnsFalse() {
        let state = makeState(currentRoute: .empty)

        XCTAssertFalse(
            subject.shouldExecute(
                action: .setCurrentRoute(.empty),
                state: state
            )
        )
    }

    func test_setCurrentRoute_differentValue_returnsTrue() {
        let route = RTCAudioStore.StoreState.AudioRoute(
            inputs: [.init(
                type: .unique,
                name: .unique,
                id: .unique,
                isExternal: false,
                isSpeaker: true,
                isReceiver: false,
                channels: 1
            )],
            outputs: []
        )
        let state = makeState(currentRoute: .empty)

        XCTAssertTrue(
            subject.shouldExecute(
                action: .setCurrentRoute(route),
                state: state
            )
        )
    }

    func test_avAudioSession_setCategory_sameValue_returnsFalse() {
        let configuration = makeAVAudioSessionConfiguration(category: .playback)
        let state = makeState(audioSessionConfiguration: configuration)

        XCTAssertFalse(
            subject.shouldExecute(
                action: .avAudioSession(.setCategory(.playback)),
                state: state
            )
        )
    }

    func test_avAudioSession_setCategory_differentValue_returnsTrue() {
        let configuration = makeAVAudioSessionConfiguration(category: .playback)
        let state = makeState(audioSessionConfiguration: configuration)

        XCTAssertTrue(
            subject.shouldExecute(
                action: .avAudioSession(.setCategory(.playAndRecord)),
                state: state
            )
        )
    }

    func test_avAudioSession_setCategoryAndModeAndOptions_matchingConfiguration_returnsFalse() {
        let configuration = makeAVAudioSessionConfiguration(
            category: .playAndRecord,
            mode: .voiceChat,
            options: [.defaultToSpeaker],
            overrideOutputAudioPort: .speaker
        )
        let state = makeState(audioSessionConfiguration: configuration)

        XCTAssertFalse(
            subject.shouldExecute(
                action: .avAudioSession(
                    .setCategoryAndModeAndCategoryOptions(
                        .playAndRecord,
                        mode: .voiceChat,
                        categoryOptions: [.defaultToSpeaker]
                    )
                ),
                state: state
            )
        )
    }

    func test_avAudioSession_setModeAndOptions_differentMode_returnsTrue() {
        let configuration = makeAVAudioSessionConfiguration(
            category: .playback,
            mode: .moviePlayback,
            options: [.mixWithOthers]
        )
        let state = makeState(audioSessionConfiguration: configuration)

        XCTAssertTrue(
            subject.shouldExecute(
                action: .avAudioSession(
                    .setModeAndCategoryOptions(
                        .spokenAudio,
                        categoryOptions: [.mixWithOthers]
                    )
                ),
                state: state
            )
        )
    }

    func test_webRTCAudioSession_setAudioEnabled_sameValue_returnsFalse() {
        let configuration = makeWebRTCAudioSessionConfiguration(isAudioEnabled: true)
        let state = makeState(webRTCAudioSessionConfiguration: configuration)

        XCTAssertFalse(
            subject.shouldExecute(
                action: .webRTCAudioSession(.setAudioEnabled(true)),
                state: state
            )
        )
    }

    func test_webRTCAudioSession_setAudioEnabled_differentValue_returnsTrue() {
        let configuration = makeWebRTCAudioSessionConfiguration(isAudioEnabled: false)
        let state = makeState(webRTCAudioSessionConfiguration: configuration)

        XCTAssertTrue(
            subject.shouldExecute(
                action: .webRTCAudioSession(.setAudioEnabled(true)),
                state: state
            )
        )
    }

    func test_callKitAction_returnsTrue() {
        let state = makeState()
        let action = RTCAudioStore.StoreAction.callKit(.activate(.sharedInstance()))

        XCTAssertTrue(
            subject.shouldExecute(
                action: action,
                state: state
            )
        )
    }

    func test_stereo_setPlayoutPreferred_sameValue_returnsFalse() {
        let stereoConfiguration = makeStereoConfiguration(preferred: true, enabled: false)
        let state = makeState(stereoConfiguration: stereoConfiguration)

        XCTAssertFalse(
            subject.shouldExecute(
                action: .stereo(.setPlayoutPreferred(true)),
                state: state
            )
        )
    }

    func test_stereo_setPlayoutPreferred_differentValue_returnsTrue() {
        let stereoConfiguration = makeStereoConfiguration(preferred: false, enabled: false)
        let state = makeState(stereoConfiguration: stereoConfiguration)

        XCTAssertTrue(
            subject.shouldExecute(
                action: .stereo(.setPlayoutPreferred(true)),
                state: state
            )
        )
    }

    func test_stereo_setPlayoutEnabled_sameValue_returnsFalse() {
        let stereoConfiguration = makeStereoConfiguration(preferred: false, enabled: true)
        let state = makeState(stereoConfiguration: stereoConfiguration)

        XCTAssertFalse(
            subject.shouldExecute(
                action: .stereo(.setPlayoutEnabled(true)),
                state: state
            )
        )
    }

    func test_stereo_setPlayoutEnabled_differentValue_returnsTrue() {
        let stereoConfiguration = makeStereoConfiguration(preferred: false, enabled: false)
        let state = makeState(stereoConfiguration: stereoConfiguration)

        XCTAssertTrue(
            subject.shouldExecute(
                action: .stereo(.setPlayoutEnabled(true)),
                state: state
            )
        )
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
            playout: .init(preferred: false, enabled: false)
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

    private func makeAVAudioSessionConfiguration(
        category: AVAudioSession.Category,
        mode: AVAudioSession.Mode = .default,
        options: AVAudioSession.CategoryOptions = [],
        overrideOutputAudioPort: AVAudioSession.PortOverride = .none
    ) -> RTCAudioStore.StoreState.AVAudioSessionConfiguration {
        .init(
            category: category,
            mode: mode,
            options: options,
            overrideOutputAudioPort: overrideOutputAudioPort
        )
    }

    private func makeWebRTCAudioSessionConfiguration(
        isAudioEnabled: Bool,
        useManualAudio: Bool = false,
        prefersNoInterruptionsFromSystemAlerts: Bool = false
    ) -> RTCAudioStore.StoreState.WebRTCAudioSessionConfiguration {
        .init(
            isAudioEnabled: isAudioEnabled,
            useManualAudio: useManualAudio,
            prefersNoInterruptionsFromSystemAlerts: prefersNoInterruptionsFromSystemAlerts
        )
    }

    private func makeStereoConfiguration(
        preferred: Bool,
        enabled: Bool
    ) -> RTCAudioStore.StoreState.StereoConfiguration {
        .init(
            playout: .init(
                preferred: preferred,
                enabled: enabled
            )
        )
    }
}
