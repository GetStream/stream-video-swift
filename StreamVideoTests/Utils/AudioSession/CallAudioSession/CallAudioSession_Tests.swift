//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
@testable import StreamVideo
import StreamWebRTC
import XCTest

final class CallAudioSession_Tests: XCTestCase, @unchecked Sendable {

    private var mockAudioStore: MockRTCAudioStore!
    private var subject: CallAudioSession!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockAudioStore = .init()
        mockAudioStore.makeShared()
        cancellables = []
    }

    override func tearDown() {
        cancellables = nil
        subject = nil
        mockAudioStore.dismantle()
        mockAudioStore = nil
        super.tearDown()
    }

    func test_init_configuresAudioSessionForCalls() async {
        let policy = MockAudioSessionPolicy()
        policy.stub(
            for: .configuration,
            with: AudioSessionConfiguration(
                isActive: true,
                category: .playAndRecord,
                mode: .voiceChat,
                options: [.allowBluetoothHFP, .allowBluetoothA2DP]
            )
        )

        subject = .init(policy: policy)

        await fulfillment {
            let configuration = self.mockAudioStore.audioStore.state.audioSessionConfiguration
            return configuration.category == .playAndRecord
                && configuration.mode == .voiceChat
                && configuration.options.contains(.allowBluetoothHFP)
                && configuration.options.contains(.allowBluetoothA2DP)
        }
    }

    func test_init_whenAnotherSessionOwnsAudio_doesNotOverrideConfiguration() async {
        let owner = String.unique

        mockAudioStore.audioStore.dispatch(.setActiveSessionIdentifier(owner))
        mockAudioStore.audioStore.dispatch(
            .avAudioSession(
                .setCategoryAndModeAndCategoryOptions(
                    .playback,
                    mode: .moviePlayback,
                    categoryOptions: [.duckOthers]
                )
            )
        )

        await fulfillment {
            let configuration = self.mockAudioStore.audioStore.state.audioSessionConfiguration
            return self.mockAudioStore.audioStore.state.activeSessionIdentifier == owner
                && configuration.category == .playback
                && configuration.mode == .moviePlayback
                && configuration.options == [.duckOthers]
        }

        subject = .init(policy: MockAudioSessionPolicy())

        await fulfillment {
            let configuration = self.mockAudioStore.audioStore.state.audioSessionConfiguration
            return self.mockAudioStore.audioStore.state.activeSessionIdentifier == owner
                && configuration.category == .playback
                && configuration.mode == .moviePlayback
                && configuration.options == [.duckOthers]
        }
    }

    func test_init_whenAnotherSessionOwnsAudio_doesNotMutateOwnershipSensitiveStoreFields() async {
        let owner = String.unique
        let ownerModule = AudioDeviceModule(MockRTCAudioDeviceModule())

        mockAudioStore.audioStore.dispatch(
            [
                .setActiveSessionIdentifier(owner),
                .setAudioDeviceModule(ownerModule),
                .webRTCAudioSession(.setAudioEnabled(true)),
                .setActive(true)
            ]
        )

        await fulfillment {
            let state = self.mockAudioStore.audioStore.state
            return state.activeSessionIdentifier == owner
                && state.audioDeviceModule === ownerModule
                && state.webRTCAudioSessionConfiguration.isAudioEnabled
                && state.isActive
        }

        // Catch any ownership-sensitive field that flips during the init
        // window. The bootstrap dispatch is conditioned on the store being
        // unowned, so none of these should ever emit while another session
        // owns the store.
        let unexpectedMutation = expectation(
            description: "init must not mutate ownership-sensitive store fields"
        )
        unexpectedMutation.isInverted = true
        Publishers
            .CombineLatest4(
                mockAudioStore.audioStore.publisher(\.activeSessionIdentifier).removeDuplicates(),
                mockAudioStore.audioStore
                    .publisher(\.audioDeviceModule)
                    .map { $0.map(ObjectIdentifier.init) }
                    .removeDuplicates(),
                mockAudioStore.audioStore.publisher(\.webRTCAudioSessionConfiguration.isAudioEnabled).removeDuplicates(),
                mockAudioStore.audioStore.publisher(\.isActive).removeDuplicates()
            )
            .dropFirst()
            .sink { _ in unexpectedMutation.fulfill() }
            .store(in: &cancellables)

        subject = .init(policy: MockAudioSessionPolicy())

        await safeFulfillment(of: [unexpectedMutation], timeout: 0.5)

        let state = mockAudioStore.audioStore.state
        XCTAssertEqual(state.activeSessionIdentifier, owner)
        XCTAssertTrue(state.audioDeviceModule === ownerModule)
        XCTAssertTrue(state.webRTCAudioSessionConfiguration.isAudioEnabled)
        XCTAssertTrue(state.isActive)
    }

    // MARK: - activate

    // MARK: shouldSetActive = true

    func test_activate_shouldSetActiveTrue_enablesAudioAndAppliesPolicy() async {
        let callSettingsSubject = PassthroughSubject<CallSettings, Never>()
        let capabilitiesSubject = PassthroughSubject<Set<OwnCapability>, Never>()
        let delegate = SpyAudioSessionAdapterDelegate()
        let statsAdapter = MockWebRTCStatsAdapter()
        let policy = MockAudioSessionPolicy()
        let mockAudioDeviceModule = MockRTCAudioDeviceModule()
        mockAudioDeviceModule.stub(for: \.isRecording, with: true)
        mockAudioDeviceModule.stub(for: \.isMicrophoneMuted, with: false)
        mockAudioStore.audioStore.dispatch(.setAudioDeviceModule(.init(mockAudioDeviceModule)))
        let policyConfiguration = AudioSessionConfiguration(
            isActive: true,
            category: .playAndRecord,
            mode: .voiceChat,
            options: [.allowBluetoothHFP, .allowBluetoothA2DP],
            overrideOutputAudioPort: .speaker
        )
        policy.stub(for: .configuration, with: policyConfiguration)

        subject = .init(policy: policy)
        await claimOwnership(of: subject)
        subject.activate(
            callSettingsPublisher: callSettingsSubject.eraseToAnyPublisher(),
            ownCapabilitiesPublisher: capabilitiesSubject.eraseToAnyPublisher(),
            delegate: delegate,
            statsAdapter: statsAdapter,
            shouldSetActive: true
        )

        // Provide call settings to trigger policy application.
        callSettingsSubject.send(CallSettings(audioOn: true, speakerOn: true))
        capabilitiesSubject.send([.sendAudio])

        await fulfillment {
            let state = self.mockAudioStore.audioStore.state
            return state.audioSessionConfiguration.category == policyConfiguration.category
                && state.audioSessionConfiguration.mode == policyConfiguration.mode
                && state.audioSessionConfiguration.options == policyConfiguration.options
                && state.isRecording
                && state.isMicrophoneMuted == false
                && state.webRTCAudioSessionConfiguration.isAudioEnabled
        }

        let traces = statsAdapter.stubbedFunctionInput[.trace]?.compactMap { input -> WebRTCTrace? in
            guard case let .trace(trace) = input else { return nil }
            return trace
        } ?? []
        XCTAssertEqual(traces.count, 2)
    }

    func test_activate_shouldSetActiveTrue_setsStereoPreference_whenPolicyPrefersStereoPlayout() async {
        let callSettingsSubject = PassthroughSubject<CallSettings, Never>()
        let capabilitiesSubject = PassthroughSubject<Set<OwnCapability>, Never>()
        let delegate = SpyAudioSessionAdapterDelegate()
        subject = .init(policy: LivestreamAudioSessionPolicy())
        await claimOwnership(of: subject)

        subject.activate(
            callSettingsPublisher: callSettingsSubject.eraseToAnyPublisher(),
            ownCapabilitiesPublisher: capabilitiesSubject.eraseToAnyPublisher(),
            delegate: delegate,
            statsAdapter: nil,
            shouldSetActive: true
        )

        await fulfillment {
            self.mockAudioStore.audioStore.state.stereoConfiguration.playout.preferred
        }
    }

    // MARK: shouldSetActive = false

    func test_activate_shouldSetActiveFalse_isActiveOnStoreAlreadyTrue_firesDeferredActivationImmediately() async {
        let callSettingsSubject = CurrentValueSubject<CallSettings, Never>(.default)
        let capabilitiesSubject = CurrentValueSubject<Set<OwnCapability>, Never>([.sendAudio])
        let delegate = SpyAudioSessionAdapterDelegate()
        let policy = MockAudioSessionPolicy()
        let policyConfiguration = AudioSessionConfiguration(
            isActive: true,
            category: .playAndRecord,
            mode: .voiceChat,
            options: [.allowBluetoothHFP, .allowBluetoothA2DP],
            overrideOutputAudioPort: .speaker
        )
        policy.stub(for: .configuration, with: policyConfiguration)
        mockAudioStore.audioStore.dispatch(.setActive(true))

        await fulfillment {
            self.mockAudioStore.audioStore.state.isActive
        }

        subject = .init(policy: policy)
        await claimOwnership(of: subject)

        subject.activate(
            callSettingsPublisher: callSettingsSubject.eraseToAnyPublisher(),
            ownCapabilitiesPublisher: capabilitiesSubject.eraseToAnyPublisher(),
            delegate: delegate,
            statsAdapter: nil,
            shouldSetActive: false
        )

        // No further `.setActive(true)` dispatch is emitted; the deferred
        // activation must still fire because the store already owned by this
        // session is active.
        await fulfillment {
            let state = self.mockAudioStore.audioStore.state
            return state.audioSessionConfiguration.category == policyConfiguration.category
                && state.audioSessionConfiguration.mode == policyConfiguration.mode
                && state.audioSessionConfiguration.options == policyConfiguration.options
                && state.isMicrophoneMuted == false
                && state.webRTCAudioSessionConfiguration.isAudioEnabled
        }
    }

    func test_activate_shouldSetActiveFalse_enablesAudioAndAppliesPolicy() async {
        let callSettingsSubject = PassthroughSubject<CallSettings, Never>()
        let capabilitiesSubject = PassthroughSubject<Set<OwnCapability>, Never>()
        let delegate = SpyAudioSessionAdapterDelegate()
        let statsAdapter = MockWebRTCStatsAdapter()
        let policy = MockAudioSessionPolicy()
        let mockAudioDeviceModule = MockRTCAudioDeviceModule()
        mockAudioDeviceModule.stub(for: \.isRecording, with: true)
        mockAudioDeviceModule.stub(for: \.isMicrophoneMuted, with: false)
        mockAudioStore.audioStore.dispatch(.setAudioDeviceModule(.init(mockAudioDeviceModule)))
        let policyConfiguration = AudioSessionConfiguration(
            isActive: true,
            category: .playAndRecord,
            mode: .voiceChat,
            options: [.allowBluetoothHFP, .allowBluetoothA2DP],
            overrideOutputAudioPort: .speaker
        )
        policy.stub(for: .configuration, with: policyConfiguration)

        subject = .init(policy: policy)
        await claimOwnership(of: subject)
        subject.activate(
            callSettingsPublisher: callSettingsSubject.eraseToAnyPublisher(),
            ownCapabilitiesPublisher: capabilitiesSubject.eraseToAnyPublisher(),
            delegate: delegate,
            statsAdapter: statsAdapter,
            shouldSetActive: false
        )

        mockAudioStore.audioStore.dispatch(.setActive(true))
        await fulfilmentInMainActor {
            self.mockAudioStore.audioStore.state.isActive
        }

        // Provide call settings to trigger policy application.
        callSettingsSubject.send(CallSettings(audioOn: true, speakerOn: true))
        capabilitiesSubject.send([.sendAudio])

        await fulfillment {
            let state = self.mockAudioStore.audioStore.state
            return state.audioSessionConfiguration.category == policyConfiguration.category
                && state.audioSessionConfiguration.mode == policyConfiguration.mode
                && state.audioSessionConfiguration.options == policyConfiguration.options
                && state.isRecording
                && state.isMicrophoneMuted == false
                && state.webRTCAudioSessionConfiguration.isAudioEnabled
        }

        let traces = statsAdapter.stubbedFunctionInput[.trace]?.compactMap { input -> WebRTCTrace? in
            guard case let .trace(trace) = input else { return nil }
            return trace
        } ?? []
        XCTAssertEqual(traces.count, 2)
    }

    func test_activate_shouldSetActiveFalse_setsStereoPreference_whenPolicyPrefersStereoPlayout() async {
        let callSettingsSubject = PassthroughSubject<CallSettings, Never>()
        let capabilitiesSubject = PassthroughSubject<Set<OwnCapability>, Never>()
        let delegate = SpyAudioSessionAdapterDelegate()
        subject = .init(policy: LivestreamAudioSessionPolicy())
        await claimOwnership(of: subject)

        subject.activate(
            callSettingsPublisher: callSettingsSubject.eraseToAnyPublisher(),
            ownCapabilitiesPublisher: capabilitiesSubject.eraseToAnyPublisher(),
            delegate: delegate,
            statsAdapter: nil,
            shouldSetActive: false
        )

        mockAudioStore.audioStore.dispatch(.setActive(true))

        await fulfillment {
            self.mockAudioStore.audioStore.state.stereoConfiguration.playout.preferred
        }
    }

    // MARK: - deactivate

    func test_deactivate_clearsDelegateAndDisablesAudio() async {
        let callSettingsSubject = PassthroughSubject<CallSettings, Never>()
        let capabilitiesSubject = PassthroughSubject<Set<OwnCapability>, Never>()
        let delegate = SpyAudioSessionAdapterDelegate()

        let policy = MockAudioSessionPolicy()
        subject = .init(policy: policy)
        await claimOwnership(of: subject)
        subject.activate(
            callSettingsPublisher: callSettingsSubject.eraseToAnyPublisher(),
            ownCapabilitiesPublisher: capabilitiesSubject.eraseToAnyPublisher(),
            delegate: delegate,
            statsAdapter: nil,
            shouldSetActive: true
        )

        callSettingsSubject.send(CallSettings(audioOn: true, speakerOn: true))
        capabilitiesSubject.send([.sendAudio])

        await fulfillment {
            self.mockAudioStore.audioStore.state.webRTCAudioSessionConfiguration.isAudioEnabled
        }

        await subject.deactivate()

        await fulfillment {
            let state = self.mockAudioStore.audioStore.state
            return state.webRTCAudioSessionConfiguration.isAudioEnabled == false
                && state.isActive == false
                && state.audioDeviceModule == nil
                && state.activeSessionIdentifier.isEmpty
        }

        XCTAssertNil(subject.delegate)
    }

    func test_deactivate_whenOwnershipMovedAway_keepsSharedAudioConfigured() async {
        let callSettingsSubject = PassthroughSubject<CallSettings, Never>()
        let capabilitiesSubject = PassthroughSubject<Set<OwnCapability>, Never>()
        let delegate = SpyAudioSessionAdapterDelegate()
        let replacementOwner = String.unique
        let replacementModule = AudioDeviceModule(MockRTCAudioDeviceModule())

        subject = .init(policy: MockAudioSessionPolicy())
        await claimOwnership(of: subject)
        subject.activate(
            callSettingsPublisher: callSettingsSubject.eraseToAnyPublisher(),
            ownCapabilitiesPublisher: capabilitiesSubject.eraseToAnyPublisher(),
            delegate: delegate,
            statsAdapter: nil,
            shouldSetActive: true
        )

        callSettingsSubject.send(CallSettings(audioOn: true, speakerOn: true))
        capabilitiesSubject.send([.sendAudio])

        await fulfillment {
            self.mockAudioStore.audioStore.state.webRTCAudioSessionConfiguration.isAudioEnabled
        }

        mockAudioStore.audioStore.dispatch(
            [
                .setActiveSessionIdentifier(replacementOwner),
                .setAudioDeviceModule(replacementModule),
                .webRTCAudioSession(.setAudioEnabled(true)),
                .setActive(true)
            ]
        )

        await fulfillment {
            let state = self.mockAudioStore.audioStore.state
            return state.activeSessionIdentifier == replacementOwner
                && state.audioDeviceModule === replacementModule
                && state.webRTCAudioSessionConfiguration.isAudioEnabled
                && state.isActive
        }

        await subject.deactivate()

        await fulfillment {
            let state = self.mockAudioStore.audioStore.state
            return state.activeSessionIdentifier == replacementOwner
                && state.audioDeviceModule === replacementModule
                && state.webRTCAudioSessionConfiguration.isAudioEnabled
                && state.isActive
        }
    }

    // MARK: - answer while in-call handoff

    func test_answerWhileInCall_handoffBetweenTwoSessions_preservesTakingOverSessionState() async {
        let sessionACallSettings = PassthroughSubject<CallSettings, Never>()
        let sessionACapabilities = PassthroughSubject<Set<OwnCapability>, Never>()
        let sessionADelegate = SpyAudioSessionAdapterDelegate()
        let sessionAPolicy = MockAudioSessionPolicy()
        sessionAPolicy.stub(
            for: .configuration,
            with: AudioSessionConfiguration(
                isActive: true,
                category: .playAndRecord,
                mode: .voiceChat,
                options: [.allowBluetoothHFP, .allowBluetoothA2DP],
                overrideOutputAudioPort: .speaker
            )
        )
        let sessionAModule = AudioDeviceModule(MockRTCAudioDeviceModule())

        // Session A: claim ownership through the same handshake the
        // `WebRTCStateAdapter.configureAudioSession` performs, then
        // activate and drive the policy.
        let sessionA: CallAudioSession = .init(policy: sessionAPolicy)
        mockAudioStore.audioStore.dispatch(
            [
                .setActiveSessionIdentifier(sessionA.identifier),
                .setAudioDeviceModule(sessionAModule)
            ]
        )
        await fulfillment {
            self.mockAudioStore.audioStore.state.activeSessionIdentifier == sessionA.identifier
                && self.mockAudioStore.audioStore.state.audioDeviceModule === sessionAModule
        }
        sessionA.activate(
            callSettingsPublisher: sessionACallSettings.eraseToAnyPublisher(),
            ownCapabilitiesPublisher: sessionACapabilities.eraseToAnyPublisher(),
            delegate: sessionADelegate,
            statsAdapter: nil,
            shouldSetActive: true
        )
        sessionACallSettings.send(CallSettings(audioOn: true, speakerOn: true))
        sessionACapabilities.send([.sendAudio])
        await fulfillment {
            self.mockAudioStore.audioStore.state.webRTCAudioSessionConfiguration.isAudioEnabled
                && self.mockAudioStore.audioStore.state.isActive
        }

        // Session B: replicates the ownership hand-off performed by
        // `WebRTCStateAdapter.configureAudioSession` on an incoming call.
        let sessionB: CallAudioSession = .init(policy: MockAudioSessionPolicy())
        let sessionBModule = AudioDeviceModule(MockRTCAudioDeviceModule())
        mockAudioStore.audioStore.dispatch(
            [
                .setActiveSessionIdentifier(sessionB.identifier),
                .setAudioDeviceModule(sessionBModule)
            ]
        )
        await fulfillment {
            self.mockAudioStore.audioStore.state.activeSessionIdentifier == sessionB.identifier
                && self.mockAudioStore.audioStore.state.audioDeviceModule === sessionBModule
        }

        // Session A's teardown now happens after session B has already
        // claimed ownership. None of A's cleanup actions should affect
        // the shared state because each of them is conditioned on A still
        // owning the store.
        await sessionA.deactivate()

        await fulfillment {
            let state = self.mockAudioStore.audioStore.state
            return state.activeSessionIdentifier == sessionB.identifier
                && state.audioDeviceModule === sessionBModule
                && state.isActive
                && state.webRTCAudioSessionConfiguration.isAudioEnabled
        }
    }

    // MARK: - didUpdatePolicy

    func test_didUpdatePolicy_reconfiguresWhenActive() async {
        let callSettingsSubject = PassthroughSubject<CallSettings, Never>()
        let capabilitiesSubject = PassthroughSubject<Set<OwnCapability>, Never>()

        let initialPolicy = MockAudioSessionPolicy()
        initialPolicy.stub(
            for: .configuration,
            with: AudioSessionConfiguration(
                isActive: true,
                category: .playAndRecord,
                mode: .voiceChat,
                options: [.allowBluetoothHFP],
                overrideOutputAudioPort: .speaker
            )
        )
        let delegate = SpyAudioSessionAdapterDelegate()
        subject = .init(policy: initialPolicy)
        await claimOwnership(of: subject)
        subject.activate(
            callSettingsPublisher: callSettingsSubject.eraseToAnyPublisher(),
            ownCapabilitiesPublisher: capabilitiesSubject.eraseToAnyPublisher(),
            delegate: delegate,
            statsAdapter: nil,
            shouldSetActive: true
        )

        callSettingsSubject.send(CallSettings(audioOn: true, speakerOn: true))
        capabilitiesSubject.send([.sendAudio])

        await fulfillment {
            self.mockAudioStore.audioStore.state.audioSessionConfiguration.options.contains(.allowBluetoothHFP)
        }

        let updatedPolicy = MockAudioSessionPolicy()
        updatedPolicy.stub(
            for: .configuration,
            with: AudioSessionConfiguration(
                isActive: true,
                category: .playAndRecord,
                mode: .voiceChat,
                options: [.allowBluetoothA2DP],
                overrideOutputAudioPort: AVAudioSession.PortOverride.none
            )
        )

        subject.didUpdatePolicy(
            updatedPolicy,
            callSettings: CallSettings(audioOn: false, speakerOn: false),
            ownCapabilities: []
        )

        await fulfillment {
            let state = self.mockAudioStore.audioStore.state
            return state.audioSessionConfiguration.options == [.allowBluetoothA2DP]
                && state.isRecording == false
                && state.isMicrophoneMuted == true
        }
    }

    // MARK: - routeChange

    func test_routeChangeWithMatchingSpeaker_reappliesPolicy() async {
        let callSettingsSubject = PassthroughSubject<CallSettings, Never>()
        let capabilitiesSubject = PassthroughSubject<Set<OwnCapability>, Never>()
        let delegate = SpyAudioSessionAdapterDelegate()
        let policy = MockAudioSessionPolicy()
        let policyConfiguration = AudioSessionConfiguration(
            isActive: true,
            category: .playAndRecord,
            mode: .voiceChat,
            options: [.allowBluetoothHFP],
            overrideOutputAudioPort: .speaker
        )
        policy.stub(for: .configuration, with: policyConfiguration)

        subject = .init(policy: policy)
        await claimOwnership(of: subject)
        subject.activate(
            callSettingsPublisher: callSettingsSubject.eraseToAnyPublisher(),
            ownCapabilitiesPublisher: capabilitiesSubject.eraseToAnyPublisher(),
            delegate: delegate,
            statsAdapter: nil,
            shouldSetActive: true
        )

        callSettingsSubject.send(CallSettings(audioOn: true, speakerOn: true))
        capabilitiesSubject.send([.sendAudio])

        await fulfillment {
            (policy.stubbedFunctionInput[.configuration]?.count ?? 0) == 1
        }

        let initialCount = policy.stubbedFunctionInput[.configuration]?.count ?? 0
        mockAudioStore.audioStore.dispatch(
            .setCurrentRoute(
                makeRoute(reason: .oldDeviceUnavailable, speakerOn: true)
            )
        )

        await fulfillment {
            (policy.stubbedFunctionInput[.configuration]?.count ?? 0) == initialCount + 1
        }
    }

    func test_routeChangeWithDifferentSpeaker_notifiesDelegate() async {
        let callSettingsSubject = PassthroughSubject<CallSettings, Never>()
        let capabilitiesSubject = PassthroughSubject<Set<OwnCapability>, Never>()
        let delegate = SpyAudioSessionAdapterDelegate()
        let policy = MockAudioSessionPolicy()
        subject = .init(policy: policy)
        await claimOwnership(of: subject)
        subject.activate(
            callSettingsPublisher: callSettingsSubject.eraseToAnyPublisher(),
            ownCapabilitiesPublisher: capabilitiesSubject.eraseToAnyPublisher(),
            delegate: delegate,
            statsAdapter: nil,
            shouldSetActive: true
        )

        callSettingsSubject.send(CallSettings(audioOn: true, speakerOn: true))
        capabilitiesSubject.send([.sendAudio])

        await fulfillment {
            (policy.stubbedFunctionInput[.configuration]?.count ?? 0) == 1
        }

        mockAudioStore.audioStore.dispatch(
            .setCurrentRoute(
                makeRoute(reason: .oldDeviceUnavailable, speakerOn: false)
            )
        )

        await fulfillment {
            delegate.speakerUpdates.contains(false)
        }

        XCTAssertEqual(policy.stubbedFunctionInput[.configuration]?.count ?? 0, 1)
    }

    // MARK: - muted speech detection

    func test_activate_whenMutedAndAllowed_enablesMutedSpeechDetection() async {
        let callSettingsSubject = PassthroughSubject<CallSettings, Never>()
        let capabilitiesSubject = PassthroughSubject<Set<OwnCapability>, Never>()
        let delegate = SpyAudioSessionAdapterDelegate()
        let policy = MockAudioSessionPolicy()
        let source = MockRTCAudioDeviceModule()
        let module = AudioDeviceModule(source)
        policy.stub(
            for: .configuration,
            with: AudioSessionConfiguration(
                isActive: true,
                category: .playAndRecord,
                mode: .voiceChat,
                options: [.allowBluetoothHFP]
            )
        )

        mockAudioStore.audioStore.dispatch([
            .setAudioDeviceModule(module),
            .setHasRecordingPermission(true)
        ])
        subject = .init(policy: policy)
        await claimOwnership(of: subject)
        subject.activate(
            callSettingsPublisher: callSettingsSubject.eraseToAnyPublisher(),
            ownCapabilitiesPublisher: capabilitiesSubject.eraseToAnyPublisher(),
            delegate: delegate,
            statsAdapter: nil,
            shouldSetActive: true
        )

        callSettingsSubject.send(CallSettings(audioOn: false))
        capabilitiesSubject.send([.sendAudio])

        await fulfillment {
            self.mockAudioStore.audioStore.state.isMutedSpeechDetectionEnabled
        }
        XCTAssertEqual(
            source.recordedInputPayload(Bool.self, for: .setRecordingAlwaysPreparedMode),
            [true]
        )
    }

    func test_activate_whenMutedSpeechDetectionReceivesSpeech_togglesDelegate() async {
        let callSettingsSubject = PassthroughSubject<CallSettings, Never>()
        let capabilitiesSubject = PassthroughSubject<Set<OwnCapability>, Never>()
        let delegate = SpyAudioSessionAdapterDelegate()
        let policy = MockAudioSessionPolicy()
        let module = AudioDeviceModule(MockRTCAudioDeviceModule())
        policy.stub(
            for: .configuration,
            with: AudioSessionConfiguration(
                isActive: true,
                category: .playAndRecord,
                mode: .voiceChat,
                options: [.allowBluetoothHFP]
            )
        )

        mockAudioStore.audioStore.dispatch([
            .setAudioDeviceModule(module),
            .setHasRecordingPermission(true)
        ])
        subject = .init(policy: policy)
        await claimOwnership(of: subject)
        subject.activate(
            callSettingsPublisher: callSettingsSubject.eraseToAnyPublisher(),
            ownCapabilitiesPublisher: capabilitiesSubject.eraseToAnyPublisher(),
            delegate: delegate,
            statsAdapter: nil,
            shouldSetActive: true
        )

        callSettingsSubject.send(CallSettings(audioOn: false))
        capabilitiesSubject.send([.sendAudio])

        await fulfillment {
            self.mockAudioStore.audioStore.state.isMutedSpeechDetectionEnabled
        }

        module.audioDeviceModule(.init(), didReceiveSpeechActivityEvent: .started)
        await fulfillment {
            delegate.speakingWhileMutedUpdates.contains(true)
        }

        module.audioDeviceModule(.init(), didReceiveSpeechActivityEvent: .ended)
        await fulfillment {
            delegate.speakingWhileMutedUpdates.contains(false)
        }
    }

    func test_activate_whenUnmuted_disablesMutedSpeechDetectionAndResetsDelegate() async {
        let callSettingsSubject = PassthroughSubject<CallSettings, Never>()
        let capabilitiesSubject = PassthroughSubject<Set<OwnCapability>, Never>()
        let delegate = SpyAudioSessionAdapterDelegate()
        let policy = MockAudioSessionPolicy()
        let module = AudioDeviceModule(MockRTCAudioDeviceModule())
        policy.stub(
            for: .configuration,
            with: AudioSessionConfiguration(
                isActive: true,
                category: .playAndRecord,
                mode: .voiceChat,
                options: [.allowBluetoothHFP]
            )
        )

        mockAudioStore.audioStore.dispatch([
            .setAudioDeviceModule(module),
            .setHasRecordingPermission(true)
        ])
        subject = .init(policy: policy)
        await claimOwnership(of: subject)
        subject.activate(
            callSettingsPublisher: callSettingsSubject.eraseToAnyPublisher(),
            ownCapabilitiesPublisher: capabilitiesSubject.eraseToAnyPublisher(),
            delegate: delegate,
            statsAdapter: nil,
            shouldSetActive: true
        )

        callSettingsSubject.send(CallSettings(audioOn: false))
        capabilitiesSubject.send([.sendAudio])
        await fulfillment {
            self.mockAudioStore.audioStore.state.isMutedSpeechDetectionEnabled
        }

        module.audioDeviceModule(.init(), didReceiveSpeechActivityEvent: .started)
        await fulfillment { delegate.speakingWhileMutedUpdates.contains(true) }

        callSettingsSubject.send(CallSettings(audioOn: true))

        await fulfillment {
            self.mockAudioStore.audioStore.state.isMutedSpeechDetectionEnabled == false
                && delegate.speakingWhileMutedUpdates.last == false
        }
    }

    func test_deactivate_whenSpeakingWhileMuted_resetsDelegate() async {
        let callSettingsSubject = PassthroughSubject<CallSettings, Never>()
        let capabilitiesSubject = PassthroughSubject<Set<OwnCapability>, Never>()
        let delegate = SpyAudioSessionAdapterDelegate()
        let policy = MockAudioSessionPolicy()
        let module = AudioDeviceModule(MockRTCAudioDeviceModule())
        policy.stub(
            for: .configuration,
            with: AudioSessionConfiguration(
                isActive: true,
                category: .playAndRecord,
                mode: .voiceChat,
                options: [.allowBluetoothHFP]
            )
        )

        mockAudioStore.audioStore.dispatch([
            .setAudioDeviceModule(module),
            .setHasRecordingPermission(true)
        ])
        subject = .init(policy: policy)
        await claimOwnership(of: subject)
        subject.activate(
            callSettingsPublisher: callSettingsSubject.eraseToAnyPublisher(),
            ownCapabilitiesPublisher: capabilitiesSubject.eraseToAnyPublisher(),
            delegate: delegate,
            statsAdapter: nil,
            shouldSetActive: true
        )

        callSettingsSubject.send(CallSettings(audioOn: false))
        capabilitiesSubject.send([.sendAudio])
        await fulfillment {
            self.mockAudioStore.audioStore.state.isMutedSpeechDetectionEnabled
        }

        module.audioDeviceModule(.init(), didReceiveSpeechActivityEvent: .started)
        await fulfillment { delegate.speakingWhileMutedUpdates.contains(true) }

        await subject.deactivate()

        XCTAssertEqual(delegate.speakingWhileMutedUpdates.last, false)
    }

    func test_currentRouteIsExternal_matchesAudioStoreState() async {
        let policy = MockAudioSessionPolicy()
        subject = .init(policy: policy)

        let externalRoute = RTCAudioStore.StoreState.AudioRoute(
            MockAVAudioSessionRouteDescription(
                outputs: [MockAVAudioSessionPortDescription(portType: .bluetoothHFP)]
            )
        )

        mockAudioStore.audioStore.dispatch(.setCurrentRoute(externalRoute))

        await fulfillment {
            self.subject.currentRouteIsExternal == true
        }
    }

    // MARK: - callOptionsCleared

    func test_callOptionsCleared_reappliesLastOptions() async {
        let callSettingsSubject = PassthroughSubject<CallSettings, Never>()
        let capabilitiesSubject = PassthroughSubject<Set<OwnCapability>, Never>()
        let delegate = SpyAudioSessionAdapterDelegate()
        let policy = MockAudioSessionPolicy()
        let policyConfiguration = AudioSessionConfiguration(
            isActive: true,
            category: .playAndRecord,
            mode: .voiceChat,
            options: [.allowBluetoothHFP]
        )
        policy.stub(for: .configuration, with: policyConfiguration)

        subject = .init(policy: policy)
        await claimOwnership(of: subject)
        subject.activate(
            callSettingsPublisher: callSettingsSubject.eraseToAnyPublisher(),
            ownCapabilitiesPublisher: capabilitiesSubject.eraseToAnyPublisher(),
            delegate: delegate,
            statsAdapter: nil,
            shouldSetActive: true
        )

        callSettingsSubject.send(CallSettings(audioOn: true, speakerOn: true))
        capabilitiesSubject.send([.sendAudio])

        await fulfillment {
            self.mockAudioStore.audioStore.state.audioSessionConfiguration.options == policyConfiguration.options
        }

        mockAudioStore.audioStore.dispatch(
            .avAudioSession(.systemSetCategoryOptions([]))
        )

        await fulfillment {
            self.mockAudioStore.audioStore.state.audioSessionConfiguration.options == policyConfiguration.options
        }
    }

    func test_callOptionsCleared_whenOwnershipMovedAway_doesNotReapplyLastOptions() async {
        let callSettingsSubject = PassthroughSubject<CallSettings, Never>()
        let capabilitiesSubject = PassthroughSubject<Set<OwnCapability>, Never>()
        let delegate = SpyAudioSessionAdapterDelegate()
        let policy = MockAudioSessionPolicy()
        let policyConfiguration = AudioSessionConfiguration(
            isActive: true,
            category: .playAndRecord,
            mode: .voiceChat,
            options: [.allowBluetoothHFP]
        )
        policy.stub(for: .configuration, with: policyConfiguration)

        subject = .init(policy: policy)
        await claimOwnership(of: subject)
        subject.activate(
            callSettingsPublisher: callSettingsSubject.eraseToAnyPublisher(),
            ownCapabilitiesPublisher: capabilitiesSubject.eraseToAnyPublisher(),
            delegate: delegate,
            statsAdapter: nil,
            shouldSetActive: true
        )

        callSettingsSubject.send(CallSettings(audioOn: true, speakerOn: true))
        capabilitiesSubject.send([.sendAudio])

        await fulfillment {
            self.mockAudioStore.audioStore.state.audioSessionConfiguration.options == policyConfiguration.options
        }

        await assignOwner(String.unique)

        let unexpectedReapply = expectation(
            description: "Stale session should not reapply cleared options."
        )
        unexpectedReapply.isInverted = true
        mockAudioStore.audioStore
            .publisher(\.audioSessionConfiguration.options)
            .dropFirst()
            .filter { !$0.isEmpty }
            .sink { _ in
                unexpectedReapply.fulfill()
            }
            .store(in: &cancellables)

        mockAudioStore.audioStore.dispatch(
            .avAudioSession(.systemSetCategoryOptions([]))
        )

        await fulfillment {
            self.mockAudioStore.audioStore.state.audioSessionConfiguration.options.isEmpty
        }

        await safeFulfillment(of: [unexpectedReapply], timeout: 0.5)
    }
}

private final class SpyAudioSessionAdapterDelegate: StreamAudioSessionAdapterDelegate, @unchecked Sendable {
    private(set) var speakerUpdates: [Bool] = []
    private(set) var speakingWhileMutedUpdates: [Bool] = []

    func audioSessionAdapterDidUpdateSpeakerOn(
        _ speakerOn: Bool,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) {
        speakerUpdates.append(speakerOn)
    }

    func audioSessionAdapterDidUpdateSpeakingWhileMuted(
        _ isSpeakingWhileMuted: Bool
    ) {
        speakingWhileMutedUpdates.append(isSpeakingWhileMuted)
    }
}

extension CallAudioSession_Tests {
    private func claimOwnership(of session: CallAudioSession) async {
        await assignOwner(session.identifier)
    }

    private func assignOwner(_ identifier: String) async {
        mockAudioStore.audioStore.dispatch(.setActiveSessionIdentifier(identifier))

        await fulfillment {
            self.mockAudioStore.audioStore.state.activeSessionIdentifier == identifier
        }
    }
}

// MARK: - Helpers

private func makeRoute(
    reason: AVAudioSession.RouteChangeReason,
    speakerOn: Bool
) -> RTCAudioStore.StoreState.AudioRoute {
    let port = RTCAudioStore.StoreState.AudioRoute.Port(
        type: speakerOn ? AVAudioSession.Port.builtInSpeaker.rawValue : AVAudioSession.Port.builtInReceiver.rawValue,
        name: speakerOn ? "speaker" : "receiver",
        id: UUID().uuidString,
        isExternal: !speakerOn,
        isSpeaker: speakerOn,
        isReceiver: !speakerOn,
        channels: speakerOn ? 2 : 1
    )
    return .init(
        inputs: [],
        outputs: [port],
        reason: reason
    )
}
