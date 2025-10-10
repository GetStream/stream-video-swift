//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation

/// `CallAudioSession` manages the audio session for calls, handling configuration,
/// activation, and deactivation.
final class CallAudioSession: @unchecked Sendable {

    @Injected(\.audioStore) private var audioStore

    var currentRouteIsExternal: Bool { audioStore.state.currentRoute.isExternal }

    private(set) weak var delegate: StreamAudioSessionAdapterDelegate?
    private(set) var statsAdapter: WebRTCStatsAdapting?

    /// The current audio session policy used to configure the session.
    /// Determines audio behaviour for the call session.
    /// Set this property to change how the session is configured.
    @Atomic private(set) var policy: AudioSessionPolicy

    private let disposableBag = DisposableBag()
    private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)

    private var lastCallSettingSpeakerOn: Bool?

    init(
        policy: AudioSessionPolicy = DefaultAudioSessionPolicy()
    ) {
        self.policy = policy

        /// - Important: This runs whenever an CallAudioSession is created and ensures that
        /// the configuration is correctly for calling. This is quite important for CallKit as if the category and
        /// mode aren't set correctly it won't activate the audioSession.
        audioStore.dispatch(
            .avAudioSession(
                .setCategoryAndModeAndCategoryOptions(
                    .playAndRecord,
                    mode: .voiceChat,
                    categoryOptions: [.allowBluetoothHFP, .allowBluetoothA2DP]
                )
            )
        )
    }

    func activate(
        callSettingsPublisher: AnyPublisher<CallSettings, Never>,
        ownCapabilitiesPublisher: AnyPublisher<Set<OwnCapability>, Never>,
        delegate: StreamAudioSessionAdapterDelegate,
        statsAdapter: WebRTCStatsAdapting?,
        shouldSetActive: Bool
    ) {
        disposableBag.removeAll()

        self.delegate = delegate
        self.statsAdapter = statsAdapter

        audioStore.dispatch(.webRTCAudioSession(.setAudioEnabled(true)))

        Publishers
            .CombineLatest(callSettingsPublisher, ownCapabilitiesPublisher)
            .receive(on: processingQueue)
            .sink { [weak self] in self?.didUpdate(callSettings: $0, ownCapabilities: $1) }
            .store(in: disposableBag)

        audioStore
            .publisher(\.currentRoute)
            .removeDuplicates()
            // We want to start listening on route changes **once** we have
            // expressed our initial preference.
            .drop { [weak self] _ in self?.lastCallSettingSpeakerOn == nil }
            .receive(on: processingQueue)
            .sink {
                [weak self] in self?.delegate?.audioSessionAdapterDidUpdateSpeakerOn(
                    $0.isSpeaker,
                    file: #file,
                    function: #function,
                    line: #line
                )
            }
            .store(in: disposableBag)

        statsAdapter?.trace(.init(audioSession: traceRepresentation))
    }

    func deactivate() {
        guard delegate != nil else {
            return
        }

        disposableBag.removeAll()
        delegate = nil

        audioStore.dispatch([
            .webRTCAudioSession(.setAudioEnabled(false)),
            .setAudioDeviceModule(nil),
            .setActive(false)
        ])

        statsAdapter?.trace(.init(audioSession: traceRepresentation))
    }

    func didUpdatePolicy(
        _ policy: AudioSessionPolicy,
        callSettings: CallSettings,
        ownCapabilities: Set<OwnCapability>
    ) {
        self.policy = policy

        guard delegate != nil else {
            return
        }

        processingQueue.addOperation { [weak self] in
            self?.didUpdate(
                callSettings: callSettings,
                ownCapabilities: ownCapabilities
            )
        }
    }

    // MARK: - Private Helpers

    private func didUpdate(
        callSettings: CallSettings,
        ownCapabilities: Set<OwnCapability>
    ) {
        defer { statsAdapter?.trace(.init(audioSession: traceRepresentation)) }

        let configuration = policy.configuration(
            for: callSettings,
            ownCapabilities: ownCapabilities
        )

        var actions: [RTCAudioStore.Namespace.Action] = [
            .avAudioSession(
                .setCategoryAndModeAndCategoryOptions(
                    configuration.category,
                    mode: configuration.mode,
                    categoryOptions: configuration.options
                )
            ),
            .avAudioSession(
                .setOverrideOutputAudioPort(configuration.overrideOutputAudioPort ?? .none)
            ),
            .setActive(configuration.isActive),
        ]

        if ownCapabilities.contains(.sendAudio) {
            actions.append(.setShouldRecord(true))
            actions.append(.setMicrophoneMuted(!callSettings.audioOn))
        } else {
            actions.append(.setShouldRecord(false))
            actions.append(.setMicrophoneMuted(true))
        }

        audioStore.dispatch(actions)
        lastCallSettingSpeakerOn = configuration.overrideOutputAudioPort == .speaker
    }
}

extension CallAudioSession {
    struct TraceRepresentation: Encodable {
        var state: RTCAudioStore.StoreState
        var hasDelegate: Bool
        var policy: String

        init(_ source: CallAudioSession) {
            state = source.audioStore.state
            hasDelegate = source.delegate != nil
            policy = String(describing: source.policy)
        }
    }

    var traceRepresentation: TraceRepresentation {
        .init(self)
    }
}
