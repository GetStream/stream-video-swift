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

    func test_deactivate_releasesStatsAdapterAndPreservesFinalTrace() async {
        let delegate = SpyAudioSessionAdapterDelegate()
        let statsAdapter = MockWebRTCStatsAdapter()
        subject = .init(policy: MockAudioSessionPolicy())
        subject.activate(
            callSettingsPublisher: Empty().eraseToAnyPublisher(),
            ownCapabilitiesPublisher: Empty().eraseToAnyPublisher(),
            delegate: delegate,
            statsAdapter: statsAdapter,
            shouldSetActive: false
        )
        let tracesBeforeDeactivation = statsAdapter.timesCalled(.trace)

        await subject.deactivate()

        XCTAssertNil(subject.statsAdapter)
        XCTAssertEqual(statsAdapter.timesCalled(.trace), tracesBeforeDeactivation + 1)
    }

    func test_deactivate_delegateReleased_releasesStatsAdapter() async {
        var delegate: SpyAudioSessionAdapterDelegate? = .init()
        subject = .init(policy: MockAudioSessionPolicy())
        subject.activate(
            callSettingsPublisher: Empty().eraseToAnyPublisher(),
            ownCapabilitiesPublisher: Empty().eraseToAnyPublisher(),
            delegate: delegate!,
            statsAdapter: MockWebRTCStatsAdapter(),
            shouldSetActive: false
        )
        delegate = nil

        await subject.deactivate()

        XCTAssertNil(subject.statsAdapter)
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

    // MARK: - audio bitrate profile

    func test_setAudioBitrateProfile_music_overridesVoiceChatToDefault() async throws {
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

        let callSettings = CallSettings(audioOn: true, speakerOn: true)
        callSettingsSubject.send(callSettings)
        capabilitiesSubject.send([.sendAudio])

        await fulfillment {
            self.mockAudioStore.audioStore.state.audioSessionConfiguration.mode
                == .voiceChat
        }

        try await subject.setAudioBitrateProfile(
            .musicHighQuality,
            callSettings: callSettings,
            ownCapabilities: [.sendAudio]
        )

        await fulfillment {
            self.mockAudioStore.audioStore.state.audioSessionConfiguration.mode
                == .default
        }

        try await subject.setAudioBitrateProfile(
            .voiceStandard,
            callSettings: callSettings,
            ownCapabilities: [.sendAudio]
        )

        await fulfillment {
            self.mockAudioStore.audioStore.state.audioSessionConfiguration.mode
                == .voiceChat
        }
    }

    func test_setAudioBitrateProfile_inactiveSession_doesNotMutateCategory(
    ) async throws {
        let callSettingsSubject = PassthroughSubject<CallSettings, Never>()
        let capabilitiesSubject = PassthroughSubject<Set<OwnCapability>, Never>()
        let delegate = SpyAudioSessionAdapterDelegate()
        let policy = MockAudioSessionPolicy()
        let policyConfiguration = AudioSessionConfiguration(
            isActive: false,
            category: .playAndRecord,
            mode: .voiceChat,
            options: [.allowBluetoothHFP],
            overrideOutputAudioPort: .none
        )
        policy.stub(for: .configuration, with: policyConfiguration)

        subject = .init(policy: policy)
        await claimOwnership(of: subject)
        await fulfillment {
            self.mockAudioStore.audioStore.state.audioSessionConfiguration.mode
                == .voiceChat
        }
        subject.activate(
            callSettingsPublisher: callSettingsSubject.eraseToAnyPublisher(),
            ownCapabilitiesPublisher: capabilitiesSubject.eraseToAnyPublisher(),
            delegate: delegate,
            statsAdapter: nil,
            shouldSetActive: false
        )

        let callSettings = CallSettings(audioOn: true, speakerOn: true)
        try await subject.setAudioBitrateProfile(
            .musicHighQuality,
            callSettings: callSettings,
            ownCapabilities: [.sendAudio]
        )

        XCTAssertEqual(
            mockAudioStore.audioStore.state.audioSessionConfiguration.mode,
            .voiceChat
        )
        XCTAssertFalse(
            subject.shouldApplyVoiceProcessing(
                callSettings: callSettings,
                ownCapabilities: [.sendAudio]
            )
        )
    }

    func test_routeChange_whileMusicMode_keepsDefaultMode() async throws {
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

        let callSettings = CallSettings(audioOn: true, speakerOn: true)
        callSettingsSubject.send(callSettings)
        capabilitiesSubject.send([.sendAudio])

        await fulfillment {
            self.mockAudioStore.audioStore.state.audioSessionConfiguration.mode
                == .voiceChat
        }

        try await subject.setAudioBitrateProfile(
            .musicHighQuality,
            callSettings: callSettings,
            ownCapabilities: [.sendAudio]
        )

        await fulfillment {
            self.mockAudioStore.audioStore.state.audioSessionConfiguration.mode
                == .default
        }

        let countAfterMusic = policy.stubbedFunctionInput[.configuration]?.count
            ?? 0
        mockAudioStore.audioStore.dispatch(
            .setCurrentRoute(
                makeRoute(reason: .oldDeviceUnavailable, speakerOn: true)
            )
        )

        await fulfillment {
            (policy.stubbedFunctionInput[.configuration]?.count ?? 0)
                == countAfterMusic + 1
        }

        XCTAssertEqual(
            mockAudioStore.audioStore.state.audioSessionConfiguration.mode,
            .default
        )
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

    func test_routeChangeWithCategoryChangeReason_isIgnored() async {
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

        // A `.categoryChange` route notification is emitted by our own
        // category/mode reconfiguration and momentarily reports the default
        // (receiver) route while the desired override is the speaker. It must
        // not be treated as a user-driven route change.
        mockAudioStore.audioStore.dispatch(
            .setCurrentRoute(
                makeRoute(reason: .categoryChange, speakerOn: false)
            )
        )

        await wait(for: 0.5)

        XCTAssertFalse(delegate.speakerUpdates.contains(false))
        XCTAssertEqual(
            policy.stubbedFunctionInput[.configuration]?.count ?? 0,
            initialCount
        )
    }

    /// Reproduces the reported join scenario (no external device connected):
    /// the OS emits a continuous stream of `.categoryChange` route
    /// notifications while joining, each momentarily reporting the default
    /// (receiver) route while the speaker override is still pending. The
    /// speaker update is fed back into call settings exactly like
    /// `WebRTCStateAdapter` does, which is what closes the loop. Before the fix
    /// this oscillates `speakerOn` and reconfigures the session endlessly,
    /// restarting the audio unit so captured microphone audio never reaches the
    /// published track.
    func test_categoryChangeStormDuringJoin_settlesWithoutReconfigurationLoop() async {
        let callSettingsSubject = CurrentValueSubject<CallSettings, Never>(
            .init(audioOn: true, speakerOn: true)
        )
        let capabilitiesSubject = CurrentValueSubject<Set<OwnCapability>, Never>(
            [.sendAudio]
        )
        let policy = MockAudioSessionPolicy()
        policy.stub(
            for: .configuration,
            with: AudioSessionConfiguration(
                isActive: true,
                category: .playAndRecord,
                mode: .voiceChat,
                options: [.allowBluetoothHFP],
                overrideOutputAudioPort: .speaker
            )
        )
        let delegate = SpeakerFeedbackAudioSessionAdapterDelegate(callSettingsSubject)

        subject = .init(policy: policy)
        await claimOwnership(of: subject)
        subject.activate(
            callSettingsPublisher: callSettingsSubject.eraseToAnyPublisher(),
            ownCapabilitiesPublisher: capabilitiesSubject.eraseToAnyPublisher(),
            delegate: delegate,
            statsAdapter: nil,
            shouldSetActive: true
        )

        await fulfillment {
            (policy.stubbedFunctionInput[.configuration]?.count ?? 0) == 1
        }

        // Model the OS feedback that drives the real loop: each time the call
        // reconfigures the AVAudioSession category, a `.categoryChange` route
        // notification fires. We seed the first one and re-emit after every
        // subsequent reconfiguration, capped so a regression surfaces as a
        // bounded storm instead of hanging the test.
        let injectionCap = 25
        var injections = 0
        var lastObservedCount = policy.stubbedFunctionInput[.configuration]?.count ?? 0

        mockAudioStore.audioStore.dispatch(
            .setCurrentRoute(makeRoute(reason: .categoryChange, speakerOn: false))
        )
        injections += 1

        for _ in 0..<injectionCap {
            await wait(for: 0.1)
            let current = policy.stubbedFunctionInput[.configuration]?.count ?? 0
            guard current > lastObservedCount, injections < injectionCap else {
                continue
            }
            lastObservedCount = current
            mockAudioStore.audioStore.dispatch(
                .setCurrentRoute(makeRoute(reason: .categoryChange, speakerOn: false))
            )
            injections += 1
        }

        // With the fix the storm never starts: the seed notification is
        // ignored, so it triggers no reconfiguration, no further notifications,
        // and the speaker selection is preserved.
        XCTAssertEqual(injections, 1)
        XCTAssertEqual(policy.stubbedFunctionInput[.configuration]?.count ?? 0, 1)
        XCTAssertFalse(delegate.speakerUpdates.contains(false))
        XCTAssertEqual(callSettingsSubject.value.speakerOn, true)

        // A genuine hardware transition is still honoured.
        mockAudioStore.audioStore.dispatch(
            .setCurrentRoute(makeRoute(reason: .oldDeviceUnavailable, speakerOn: false))
        )
        await fulfillment { delegate.speakerUpdates.contains(false) }
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

/// Mirrors `WebRTCStateAdapter` by feeding speaker updates back into the call
/// settings the audio session observes, so route-change handling can be tested
/// with the same feedback loop the SDK uses in production.
private final class SpeakerFeedbackAudioSessionAdapterDelegate: StreamAudioSessionAdapterDelegate, @unchecked Sendable {
    private let callSettingsSubject: CurrentValueSubject<CallSettings, Never>
    private(set) var speakerUpdates: [Bool] = []
    private(set) var speakingWhileMutedUpdates: [Bool] = []

    init(_ callSettingsSubject: CurrentValueSubject<CallSettings, Never>) {
        self.callSettingsSubject = callSettingsSubject
    }

    func audioSessionAdapterDidUpdateSpeakerOn(
        _ speakerOn: Bool,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) {
        speakerUpdates.append(speakerOn)
        callSettingsSubject.send(
            callSettingsSubject.value.withUpdatedSpeakerState(speakerOn)
        )
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

final class CallAudioSession_InitializationOrder_Tests: XCTestCase,
    @unchecked Sendable {

    private var mockAudioStore: MockRTCAudioStore!
    private var subject: CallAudioSession!
    private var peerConnectionFactory: PeerConnectionFactory!
    private var observer: InitializationOrderAudioObserver!
    private var callSettings: CurrentValueSubject<CallSettings, Never>!
    private var capabilities: CurrentValueSubject<Set<OwnCapability>, Never>!
    private var delegate: SpyAudioSessionAdapterDelegate!
    private var peerConnections: [RTCPeerConnection]!

    override func setUp() async throws {
        try await super.setUp()
        mockAudioStore = .init()
        mockAudioStore.makeShared()
        peerConnections = []
        callSettings = .init(CallSettings(audioOn: true, videoOn: false))
        capabilities = .init([.sendAudio])
        delegate = .init()
        subject = .init()
        try await mockAudioStore.audioStore.dispatch([
            .setActive(false),
            .setActiveSessionIdentifier(subject.identifier)
        ]).result()

        peerConnectionFactory = .build(
            audioProcessingModule: MockAudioProcessingModule.shared,
            audioEngineAvailabilityOverride: false
        )
        let module = peerConnectionFactory.audioDeviceModule
        try module.setEngineAvailability(true)
        try module.setMuted(true)
        try await mockAudioStore.audioStore.dispatch(
            .setAudioDeviceModule(module)
        ).result()
        observer = .init(
            forwardingTo: module,
            audioSession: mockAudioStore.audioSession
        )
        peerConnectionFactory.factory.audioDeviceModule.observer = observer
    }

    override func tearDown() async throws {
        await subject?.deactivate()
        try await mockAudioStore?.audioStore.dispatch(
            .setAudioDeviceModule(nil)
        ).result()
        peerConnections?.forEach { $0.close() }
        peerConnections = nil
        peerConnectionFactory?.factory.audioDeviceModule.observer = nil
        observer = nil
        peerConnectionFactory = nil
        subject = nil
        delegate = nil
        callSettings = nil
        capabilities = nil
        mockAudioStore?.dismantle()
        mockAudioStore = nil
        try await super.tearDown()
    }

    func test_activate_inactiveSession_activatesBeforeNativeConfiguration_()
        async throws {
        XCTAssertFalse(mockAudioStore.audioSession.isActive)
        XCTAssertFalse(peerConnectionFactory.factory.audioDeviceModule.isRecording)

        activate(shouldSetActive: true)
        await waitForNativeConfiguration()

        XCTAssertEqual(
            observer.recordingSessionActivity.first,
            true,
            "Session must be active when native willEnableEngine returns."
        )
    }

    func test_activate_callKit_defersNativeConfigurationUntilSystemActivation_()
        async throws {
        try peerConnectionFactory.audioDeviceModule.setEngineAvailability(false)
        activate(shouldSetActive: false)
        try await mockAudioStore.audioStore.dispatch(.setActive(false)).result()

        XCTAssertFalse(mockAudioStore.audioSession.isActive)
        XCTAssertTrue(observer.recordingSessionActivity.isEmpty)
        XCTAssertFalse(peerConnectionFactory.factory.audioDeviceModule.isRecording)
        XCTAssertFalse(peerConnectionFactory.factory.audioDeviceModule.isEngineRunning)

        try await mockAudioStore.audioStore.dispatch(
            .callKit(.activate(.sharedInstance()))
        ).result()
        await waitForNativeConfiguration()

        XCTAssertEqual(observer.recordingSessionActivity.first, true)
        try await mockAudioStore.audioStore.dispatch(
            .callKit(.deactivate(.sharedInstance()))
        ).result()
    }

    func test_makePeerConnection_captureBeforeTransport_rebuildsNativeEngine_()
        async throws {
        try await prepareManualCapture()
        try await startManualCapture()
        let stops = observer.stopCount
        let releases = observer.releaseCount

        try makePeerConnection()

        XCTAssertEqual(observer.stopCount, stops + 1)
        XCTAssertEqual(observer.releaseCount, releases + 1)
        XCTAssertTrue(peerConnectionFactory.factory.audioDeviceModule.isRecording)
        XCTAssertEqual(observer.engine?.isRunning, true)
    }

    func test_join_audioReadinessPending_preparesTransportBeforeCapture_()
        async throws {
        let previousTimeout = WebRTCConfiguration.timeout
        WebRTCConfiguration.timeout.audioSessionConfigurationCompletion = 60
        defer { WebRTCConfiguration.timeout = previousTimeout }
        let permissions = MockPermissionsStore()
        defer { permissions.dismantle() }
        try await mockAudioStore.audioStore.dispatch(.setAudioDeviceModule(nil)).result()
        try await prepareManualCapture()
        try peerConnectionFactory.audioDeviceModule.setMuted(true)
        try await mockAudioStore.audioStore.dispatch(.setCurrentRoute(.empty)).result()

        let sfuStack = MockSFUStack()
        let coordinator = WebRTCCoordinator(
            user: .dummy(),
            apiKey: .unique,
            callCid: "default:\(String.unique)",
            videoConfig: .dummy(),
            callSettings: callSettings.value,
            clientEventReporter: MockClientEventReporter(),
            peerConnectionFactory: peerConnectionFactory,
            rtcPeerConnectionCoordinatorFactory: MockRTCPeerConnectionCoordinatorFactory(),
            callAuthentication: MockCallAuthenticator().authenticate
        )
        await coordinator.stateAdapter.set(sfuAdapter: sfuStack.adapter)
        await coordinator.stateAdapter.enqueueOwnCapabilities { [.sendAudio] }
        let context = WebRTCCoordinator.StateMachine.Stage.Context(
            coordinator: coordinator
        )
        let stage = WebRTCCoordinator.StateMachine.Stage.joining(context)
        stage.context.joinSource = .inApp
        stage.context.audioSessionWatchdog = .init()
        let response = sfuStack.adapter.publisherSendEvent
            .compactMap { $0 as? SFUAdapter.JoinEvent }
            .prefix(1)
            .sink { _ in sfuStack.receiveEvent(.joinResponse(.init())) }
        defer {
            response.cancel()
            stage.willTransitionAway()
        }

        _ = stage.transition(from: .connected(context))
        await fulfillment {
            !self.peerConnectionFactory.audioDeviceModule.isMicrophoneMuted
                && self.mockAudioStore.audioStore.state
                .webRTCAudioSessionConfiguration.isAudioEnabled
        }
        try peerConnectionFactory.audioDeviceModule.setEngineAvailability(true)
        await waitForRecording()
        let stops = observer.stopCount
        let releases = observer.releaseCount

        try makePeerConnection()

        XCTAssertEqual(observer.stopCount, stops)
        XCTAssertEqual(observer.releaseCount, releases)
        XCTAssertEqual(observer.engine?.isRunning, true)
        stage.willTransitionAway()
        await coordinator.stateAdapter.cleanUp()
    }

    func test_makePeerConnection_transportPreparedBeforeManualCapture_keepsNativeEngine_()
        async throws {
        try await prepareManualCapture()
        try makePeerConnection()
        try await startManualCapture()
        let stops = observer.stopCount
        let releases = observer.releaseCount

        try makePeerConnection()

        XCTAssertEqual(observer.stopCount, stops)
        XCTAssertEqual(observer.releaseCount, releases)
        XCTAssertTrue(peerConnectionFactory.factory.audioDeviceModule.isRecording)
        XCTAssertEqual(observer.engine?.isRunning, true)
    }

    private func activate(shouldSetActive: Bool) {
        subject.activate(
            callSettingsPublisher: callSettings.eraseToAnyPublisher(),
            ownCapabilitiesPublisher: capabilities.eraseToAnyPublisher(),
            delegate: delegate,
            statsAdapter: nil,
            shouldSetActive: shouldSetActive
        )
    }

    private func waitForNativeConfiguration() async {
        await fulfillment {
            !self.observer.recordingSessionActivity.isEmpty
                && self.mockAudioStore.audioStore.state.isActive
        }
    }

    private func prepareManualCapture() async throws {
        try peerConnectionFactory.audioDeviceModule.setEngineAvailability(false)
        XCTAssertEqual(
            peerConnectionFactory.factory.audioDeviceModule.setManualRenderingMode(true),
            0
        )
        try await mockAudioStore.audioStore.dispatch(.setActive(true)).result()
    }

    private func startManualCapture() async throws {
        activate(shouldSetActive: true)
        await fulfillment {
            !self.peerConnectionFactory.audioDeviceModule.isMicrophoneMuted
                && self.mockAudioStore.audioStore.state
                .webRTCAudioSessionConfiguration.isAudioEnabled
        }
        try peerConnectionFactory.audioDeviceModule.setEngineAvailability(true)
        await waitForRecording()
    }

    private func waitForRecording() async {
        await fulfillment {
            !self.observer.recordingSessionActivity.isEmpty
                && self.mockAudioStore.audioStore.state.isActive
                && self.peerConnectionFactory.factory.audioDeviceModule.isRecording
                && self.observer.engine?.isRunning == true
        }
        XCTAssertEqual(observer.engine?.isRunning, true)
        XCTAssertTrue(peerConnectionFactory.factory.audioDeviceModule.isRecording)
        XCTAssertFalse(observer.recordingSessionActivity.isEmpty)
    }

    private func makePeerConnection() throws {
        let configuration = RTCConfiguration()
        configuration.sdpSemantics = .unifiedPlan
        peerConnections.append(try peerConnectionFactory.makePeerConnection(
            configuration: configuration,
            constraints: .defaultConstraints,
            delegate: nil
        ))
    }
}

private final class InitializationOrderAudioObserver: NSObject,
    RTCAudioDeviceModuleDelegate, @unchecked Sendable {

    private let delegate: AudioDeviceModule
    private let audioSession: RTCAudioSession
    @Atomic private(set) var recordingSessionActivity: [Bool] = []
    @Atomic private(set) var engine: AVAudioEngine?
    @Atomic private(set) var stopCount = 0
    @Atomic private(set) var releaseCount = 0

    init(forwardingTo delegate: AudioDeviceModule, audioSession: RTCAudioSession) {
        self.delegate = delegate
        self.audioSession = audioSession
        super.init()
    }

    func audioDeviceModule(
        _ module: RTCAudioDeviceModule,
        didReceiveSpeechActivityEvent event: RTCSpeechActivityEvent
    ) {
        delegate.audioDeviceModule(module, didReceiveSpeechActivityEvent: event)
    }

    func audioDeviceModule(
        _ module: RTCAudioDeviceModule, didCreateEngine engine: AVAudioEngine
    ) -> Int {
        self.engine = engine
        return delegate.audioDeviceModule(module, didCreateEngine: engine)
    }

    func audioDeviceModule(
        _ module: RTCAudioDeviceModule,
        willEnableEngine engine: AVAudioEngine,
        isPlayoutEnabled: Bool,
        isRecordingEnabled: Bool
    ) -> Int {
        let result = delegate.audioDeviceModule(
            module, willEnableEngine: engine,
            isPlayoutEnabled: isPlayoutEnabled,
            isRecordingEnabled: isRecordingEnabled
        )
        // Sample synchronously after the owner can prepare the session, before
        // WebRTC continues into native node and Voice Processing configuration.
        if isRecordingEnabled {
            _recordingSessionActivity.mutate { $0.append(audioSession.isActive) }
        }
        return result
    }

    func audioDeviceModule(
        _ module: RTCAudioDeviceModule,
        willStartEngine engine: AVAudioEngine,
        isPlayoutEnabled: Bool,
        isRecordingEnabled: Bool
    ) -> Int {
        delegate.audioDeviceModule(
            module, willStartEngine: engine,
            isPlayoutEnabled: isPlayoutEnabled,
            isRecordingEnabled: isRecordingEnabled
        )
    }

    func audioDeviceModule(
        _ module: RTCAudioDeviceModule,
        didStopEngine engine: AVAudioEngine,
        isPlayoutEnabled: Bool,
        isRecordingEnabled: Bool
    ) -> Int {
        _stopCount.mutate { $0 += 1 }
        return delegate.audioDeviceModule(
            module, didStopEngine: engine,
            isPlayoutEnabled: isPlayoutEnabled,
            isRecordingEnabled: isRecordingEnabled
        )
    }

    func audioDeviceModule(
        _ module: RTCAudioDeviceModule,
        didDisableEngine engine: AVAudioEngine,
        isPlayoutEnabled: Bool,
        isRecordingEnabled: Bool
    ) -> Int {
        delegate.audioDeviceModule(
            module, didDisableEngine: engine,
            isPlayoutEnabled: isPlayoutEnabled,
            isRecordingEnabled: isRecordingEnabled
        )
    }

    func audioDeviceModule(
        _ module: RTCAudioDeviceModule, willReleaseEngine engine: AVAudioEngine
    ) -> Int {
        _releaseCount.mutate { $0 += 1 }
        if self.engine === engine {
            self.engine = nil
        }
        return delegate.audioDeviceModule(module, willReleaseEngine: engine)
    }

    func audioDeviceModule(
        _ module: RTCAudioDeviceModule,
        engine: AVAudioEngine,
        configureInputFromSource source: AVAudioNode?,
        toDestination destination: AVAudioNode,
        format: AVAudioFormat,
        context: [AnyHashable: Any]
    ) -> Int {
        var input = source
        if engine.isInManualRenderingMode, input == nil {
            let silence = AVAudioSourceNode { _, _, _, audioBufferList in
                for buffer in UnsafeMutableAudioBufferListPointer(audioBufferList) {
                    if let data = buffer.mData {
                        memset(data, 0, Int(buffer.mDataByteSize))
                    }
                }
                return noErr
            }
            engine.attach(silence)
            engine.connect(
                silence, to: destination,
                format: AVAudioFormat(
                    standardFormatWithSampleRate: format.sampleRate,
                    channels: 1
                )
            )
            input = silence
        }
        return delegate.audioDeviceModule(
            module, engine: engine, configureInputFromSource: input,
            toDestination: destination, format: format, context: context
        )
    }

    func audioDeviceModule(
        _ module: RTCAudioDeviceModule,
        engine: AVAudioEngine,
        configureOutputFromSource source: AVAudioNode,
        toDestination destination: AVAudioNode?,
        format: AVAudioFormat,
        context: [AnyHashable: Any]
    ) -> Int {
        delegate.audioDeviceModule(
            module, engine: engine, configureOutputFromSource: source,
            toDestination: destination, format: format, context: context
        )
    }

    func audioDeviceModuleDidUpdateDevices(_ module: RTCAudioDeviceModule) {
        delegate.audioDeviceModuleDidUpdateDevices(module)
    }

    func audioDeviceModule(
        _ module: RTCAudioDeviceModule,
        didUpdateAudioProcessingState state: RTCAudioProcessingState
    ) {
        delegate.audioDeviceModule(module, didUpdateAudioProcessingState: state)
    }
}
