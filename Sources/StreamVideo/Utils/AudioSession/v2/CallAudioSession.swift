//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation

final class CallAudioSession: @unchecked Sendable {

    @Injected(\.audioStore) private var audioStore
    @Injected(\.callKitAdapter) private var callKitAdapter
    @Injected(\.applicationStateAdapter) private var applicationStateAdapter

    var currentRoute: AVAudioSessionRouteDescription { audioStore.session.currentRoute }

    @Atomic private(set) var policy: AudioSessionPolicy

    private let disposableBag = DisposableBag()
    private weak var delegate: StreamAudioSessionAdapterDelegate?

    private var interruptionEffect: RTCAudioStore.InterruptionEffect?
    private var routeChangeEffect: RTCAudioStore.RouteChangeEffect?
    private var hasBeenActivated = false

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
        shouldSetActive: Bool
    ) {
        disposableBag.removeAll()

        self.delegate = delegate
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

        audioStore.dispatch(.rtc(.isAudioEnabled(true)))

        if shouldSetActive {
            audioStore.dispatch(.rtc(.isActive(true)))
        }
    }

    func deactivate() {
        guard delegate != nil else {
            return
        }

        disposableBag.removeAll()
        delegate = nil
        interruptionEffect = nil
        routeChangeEffect = nil
        audioStore.dispatch(.rtc(.isActive(false)))
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
        guard
            !Task.isCancelled
        else {
            return
        }

        do {
            try await audioStore.dispatch(
                .rtc(
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
                try await audioStore.dispatch(
                    .rtc(
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
    }

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
            .rtc(
                .setCategory(
                    .playAndRecord,
                    mode: .voiceChat,
                    options: .allowBluetooth
                )
            )
        )
    }
}
