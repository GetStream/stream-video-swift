//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation

/// `CallAudioSession` manages the audio session for calls, handling configuration,
/// activation, and deactivation.
final class CallAudioSession: @unchecked Sendable, Encodable {

    @Injected(\.audioStore) private var audioStore

    var currentRoute: AVAudioSessionRouteDescription { audioStore.session.currentRoute }

    private(set) weak var delegate: StreamAudioSessionAdapterDelegate?
    private(set) var statsAdapter: WebRTCStatsAdapting?

    /// The current audio session policy used to configure the session.
    /// Determines audio behavior for the call session.
    /// Set this property to change how the session is configured.
    @Atomic private(set) var policy: AudioSessionPolicy

    private let disposableBag = DisposableBag()

    private var interruptionEffect: RTCAudioStore.InterruptionEffect?
    private var routeChangeEffect: RTCAudioStore.RouteChangeEffect?

    init(
        policy: AudioSessionPolicy = DefaultAudioSessionPolicy()
    ) {
        self.policy = policy

        initialAudioSessionConfiguration()
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
        interruptionEffect = .init(audioStore)
        routeChangeEffect = .init(
            audioStore,
            callSettingsPublisher: callSettingsPublisher,
            delegate: delegate
        )

        Publishers
            .CombineLatest(callSettingsPublisher, ownCapabilitiesPublisher)
            .compactMap { [policy] in policy.configuration(for: $0, ownCapabilities: $1) }
            .removeDuplicates()
            .sinkTask(storeIn: disposableBag) { [weak self] in await self?.didUpdateConfiguration($0) }
            .store(in: disposableBag)

        audioStore.dispatch(.audioSession(.isAudioEnabled(true)))

        if shouldSetActive {
            audioStore.dispatch(.audioSession(.isActive(true)))
        }

        statsAdapter?.trace(.init(audioSession: self))
    }

    func deactivate() {
        guard delegate != nil else {
            return
        }

        disposableBag.removeAll()
        delegate = nil
        interruptionEffect = nil
        routeChangeEffect = nil
        audioStore.dispatch(.audioSession(.isActive(false)))
        statsAdapter?.trace(.init(audioSession: self))
    }

    func didUpdatePolicy(
        _ policy: AudioSessionPolicy,
        callSettings: CallSettings,
        ownCapabilities: Set<OwnCapability>
    ) {
        self.policy = policy
        Task(disposableBag: disposableBag) { [weak self] in
            guard let self else { return }
            await didUpdateConfiguration(
                policy.configuration(for: callSettings, ownCapabilities: ownCapabilities)
            )
        }
    }

    // MARK: - Encodable

    /// Restricts encoding to only serializable properties.
    /// Only `policy` is encoded if it conforms to `Encodable`.
    enum CodingKeys: String, CodingKey {
        case state
        case hasDelegate
        case hasInterruptionEffect
        case hasRouteChangeEffect
        case policy
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(audioStore.state, forKey: .state)
        try container.encode(delegate != nil, forKey: .hasDelegate)
        try container.encode(interruptionEffect != nil, forKey: .hasInterruptionEffect)
        try container.encode(routeChangeEffect != nil, forKey: .hasRouteChangeEffect)
        try container.encode("\(type(of: policy))", forKey: .policy)
    }

    // MARK: - Private Helpers

    private func didUpdateConfiguration(
        _ configuration: AudioSessionConfiguration
    ) async {
        guard
            !Task.isCancelled
        else {
            return
        }

        do {
            try await audioStore.dispatchAsync(
                .audioSession(
                    .setCategory(
                        configuration.category,
                        mode: configuration.mode,
                        options: configuration.options
                    )
                )
            )
        } catch {
            log.error(
                "Unable to apply configuration category:\(configuration.category) mode:\(configuration.mode) options:\(configuration.options).",
                subsystems: .audioSession,
                error: error
            )
        }

        if let overrideOutputAudioPort = configuration.overrideOutputAudioPort {
            do {
                try await audioStore.dispatchAsync(
                    .audioSession(
                        .setOverrideOutputPort(overrideOutputAudioPort)
                    )
                )
            } catch {
                log.error(
                    "Unable to apply configuration overrideOutputAudioPort:\(overrideOutputAudioPort).",
                    subsystems: .audioSession,
                    error: error
                )
            }
        }

        statsAdapter?.trace(.init(audioSession: self))
    }

    /// - Important: This method runs whenever an CallAudioSession is created and ensures that
    /// the configuration is correctly for calling. This is quite important for CallKit as if the category and
    /// mode aren't set correctly it won't activate the audioSession.
    private func initialAudioSessionConfiguration() {
        let state = audioStore.state
        let requiresCategoryUpdate = state.category != .playAndRecord
        let requiresModeUpdate = state.mode != .voiceChat && state.mode != .videoChat

        guard requiresCategoryUpdate || requiresModeUpdate else {
            log.info(
                "AudioSession initial configuration isn't required.",
                subsystems: .audioSession
            )
            return
        }

        audioStore.dispatch(
            .audioSession(
                .setCategory(
                    .playAndRecord,
                    mode: .voiceChat,
                    options: .allowBluetooth
                )
            )
        )
    }
}
