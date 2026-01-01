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

    func test_activate_enablesAudioAndAppliesPolicy() async {
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

    func test_deactivate_clearsDelegateAndDisablesAudio() async {
        let callSettingsSubject = PassthroughSubject<CallSettings, Never>()
        let capabilitiesSubject = PassthroughSubject<Set<OwnCapability>, Never>()
        let delegate = SpyAudioSessionAdapterDelegate()

        let policy = MockAudioSessionPolicy()
        subject = .init(policy: policy)
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

        subject.deactivate()

        await fulfillment {
            let state = self.mockAudioStore.audioStore.state
            return state.webRTCAudioSessionConfiguration.isAudioEnabled == false
                && state.isActive == false
                && state.audioDeviceModule == nil
        }

        XCTAssertNil(subject.delegate)
    }

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

    func test_activate_setsStereoPreference_whenPolicyPrefersStereoPlayout() async {
        let callSettingsSubject = PassthroughSubject<CallSettings, Never>()
        let capabilitiesSubject = PassthroughSubject<Set<OwnCapability>, Never>()
        let delegate = SpyAudioSessionAdapterDelegate()
        subject = .init(policy: LivestreamAudioSessionPolicy())

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
}

private final class SpyAudioSessionAdapterDelegate: StreamAudioSessionAdapterDelegate, @unchecked Sendable {
    private(set) var speakerUpdates: [Bool] = []

    func audioSessionAdapterDidUpdateSpeakerOn(
        _ speakerOn: Bool,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) {
        speakerUpdates.append(speakerOn)
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
