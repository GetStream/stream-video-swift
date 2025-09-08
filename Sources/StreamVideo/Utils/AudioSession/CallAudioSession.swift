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

    var currentRoute: AVAudioSessionRouteDescription { audioStore.session.currentRoute }

    private(set) weak var delegate: StreamAudioSessionAdapterDelegate?
    private(set) var statsAdapter: WebRTCStatsAdapting?

    /// The current audio session policy used to configure the session.
    /// Determines audio behaviour for the call session.
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
            // We add a little debounce delay to avoid multiple requests to
            // overwhelm the AVAudioSession. The value has been set empirically
            // and it can be adapter if required.
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.global(qos: .userInteractive))
            .log(.debug, subsystems: .audioSession) { "Updated configuration: \($0)" }
            .sinkTask(storeIn: disposableBag) { [weak self] in await self?.didUpdateConfiguration($0) }
            .store(in: disposableBag)

        audioStore.dispatch(.audioSession(.isAudioEnabled(true)))

        if shouldSetActive {
            audioStore.dispatch(.audioSession(.isActive(true)))
        } else {
            // In this codepath it means that we are being activated from CallKit.
            // As CallKit is taking over the audioSession we perform a quick
            // restart to ensure that our configuration has been activated
            // and respected.
            audioStore.restartAudioSession()
        }

        statsAdapter?.trace(.init(audioSession: traceRepresentation))
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
        statsAdapter?.trace(.init(audioSession: traceRepresentation))
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

    // MARK: - Private Helpers

    private func didUpdateConfiguration(
        _ configuration: AudioSessionConfiguration
    ) async {
        defer { statsAdapter?.trace(.init(audioSession: traceRepresentation)) }

        guard
            !Task.isCancelled
        else {
            return
        }

        do {
            if configuration.isActive {
                try await audioStore.dispatchAsync(
                    .audioSession(
                        .setCategory(
                            configuration.category,
                            mode: configuration.mode,
                            options: configuration.options
                        )
                    )
                )
            }
        } catch {
            log.error(
                "Unable to apply configuration category:\(configuration.category) mode:\(configuration.mode) options:\(configuration.options).",
                subsystems: .audioSession,
                error: error
            )
        }

        if configuration.isActive, let overrideOutputAudioPort = configuration.overrideOutputAudioPort {
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
        
        await handleAudioOutputUpdateIfRequired(configuration)
    }

    private func handleAudioOutputUpdateIfRequired(
        _ configuration: AudioSessionConfiguration
    ) async {
        guard
            configuration.isActive != audioStore.state.isActive
        else {
            return
        }
        do {
            try await audioStore.dispatchAsync(
                .audioSession(
                    .setAVAudioSessionActive(configuration.isActive)
                )
            )
        } catch {
            log.error(
                "Failed while to applying AudioSession isActive:\(configuration.isActive) in order to match CallSettings.audioOutputOn.",
                subsystems: .audioSession,
                error: error
            )
        }
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

extension CallAudioSession {
    struct TraceRepresentation: Encodable {
        var state: RTCAudioStore.State
        var hasDelegate: Bool
        var hasInterruptionEffect: Bool
        var hasRouteChangeEffect: Bool
        var policy: String

        init(_ source: CallAudioSession) {
            state = source.audioStore.state
            hasDelegate = source.delegate != nil
            hasInterruptionEffect = source.interruptionEffect != nil
            hasRouteChangeEffect = source.routeChangeEffect != nil
            policy = String(describing: source.policy)
        }
    }

    var traceRepresentation: TraceRepresentation {
        .init(self)
    }
}
