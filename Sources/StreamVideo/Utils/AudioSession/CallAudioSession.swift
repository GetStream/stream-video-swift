//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation

enum StereoPlayoutMode {
    case none
    case deviceOnly
    case externalOnly
    case deviceAndExternal
}

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
    private var stereoPlayoutMode: StereoPlayoutMode

    private let disposableBag = DisposableBag()
    private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)

    private var lastAppliedConfiguration: AudioSessionConfiguration?
    private var lastCallSettings: CallSettings?
    private var lastOwnCapabilities: Set<OwnCapability>?

    init(
        stereoPlayoutMode: StereoPlayoutMode = .deviceAndExternal,
        policy: AudioSessionPolicy = DefaultAudioSessionPolicy()
    ) {
        self.stereoPlayoutMode = stereoPlayoutMode
        self.policy = policy

        /// - Important: This runs whenever an CallAudioSession is created and ensures that
        /// the configuration is correctly for calling. This is quite important for CallKit as if the category and
        /// mode aren't set correctly it won't activate the audioSession.
        audioStore.dispatch(
            .avAudioSession(
                .setCategoryAndModeAndCategoryOptions(
                    .playAndRecord,
                    mode: stereoPlayoutMode == .deviceAndExternal ? .default : .voiceChat,
                    categoryOptions: stereoPlayoutMode == .deviceAndExternal || stereoPlayoutMode == .externalOnly
                        ? [.allowBluetoothA2DP]
                        : [.allowBluetooth, .allowBluetoothA2DP]
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

        configureCallSettingsAndCapabilitiesObservation(
            callSettingsPublisher: callSettingsPublisher,
            ownCapabilitiesPublisher: ownCapabilitiesPublisher
        )
        configureCurrentRouteObservation()

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
            guard let self else { return }
            didUpdate(
                callSettings: callSettings,
                ownCapabilities: ownCapabilities,
                currentRoute: audioStore.state.currentRoute
            )
        }
    }

    // MARK: - Private Helpers

    private func configureCallSettingsAndCapabilitiesObservation(
        callSettingsPublisher: AnyPublisher<CallSettings, Never>,
        ownCapabilitiesPublisher: AnyPublisher<Set<OwnCapability>, Never>
    ) {
        Publishers
            .CombineLatest(callSettingsPublisher, ownCapabilitiesPublisher)
            .receive(on: processingQueue)
            .sink { [weak self] in
                guard let self else {
                    return
                }
                didUpdate(
                    callSettings: $0,
                    ownCapabilities: $1,
                    currentRoute: audioStore.state.currentRoute
                )
            }
            .store(in: disposableBag)
    }

    private func configureCurrentRouteObservation() {
        audioStore
            .publisher(\.currentRoute)
            .removeDuplicates()
            .debounce(for: .milliseconds(500), scheduler: processingQueue)
            .receive(on: processingQueue)
            .sink { [weak self] in
                guard let self, let lastCallSettings, let lastOwnCapabilities else { return }
                if lastCallSettings.speakerOn != $0.isSpeaker, $0.reason == .override {
                    self.delegate?.audioSessionAdapterDidUpdateSpeakerOn(
                        $0.isSpeaker,
                        file: #file,
                        function: #function,
                        line: #line
                    )
                } else {
                    didUpdate(
                        callSettings: lastCallSettings,
                        ownCapabilities: lastOwnCapabilities,
                        currentRoute: $0
                    )
                }
            }
            .store(in: disposableBag)
    }

    private func didUpdate(
        callSettings: CallSettings,
        ownCapabilities: Set<OwnCapability>,
        currentRoute: RTCAudioStore.StoreState.AudioRoute,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        defer { statsAdapter?.trace(.init(audioSession: traceRepresentation)) }

        var configuration = policy.configuration(
            for: callSettings,
            ownCapabilities: ownCapabilities
        )

        if !callSettings.audioOn {
            configuration = configuration
                .withStereoPlayoutMode(stereoPlayoutMode, currentRoute: currentRoute)
        }

        applyConfiguration(
            configuration,
            callSettings: callSettings,
            ownCapabilities: ownCapabilities,
            file: file,
            function: function,
            line: line
        )
    }

    private func applyConfiguration(
        _ configuration: AudioSessionConfiguration,
        callSettings: CallSettings,
        ownCapabilities: Set<OwnCapability>,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        guard configuration != lastAppliedConfiguration || callSettings != lastCallSettings || ownCapabilities !=
            lastOwnCapabilities else {
            log.debug(
                "CallAudioSession won't apply configuration:\(configuration) as it's the same as the last applied one.",
                subsystems: .audioSession,
                functionName: function,
                fileName: file,
                lineNumber: line
            )
            return
        }

        log.debug(
            "CallAudioSession will apply configuration:\(configuration)",
            subsystems: .audioSession,
            functionName: function,
            fileName: file,
            lineNumber: line
        )

        var actions: [RTCAudioStore.Namespace.Action] = []

        actions.append(
            .avAudioSession(
                .setCategoryAndModeAndCategoryOptions(
                    configuration.category,
                    mode: configuration.mode,
                    categoryOptions: configuration.options
                )
            )
        )

        actions.append(contentsOf: [
            .setActive(configuration.isActive),
            .avAudioSession(
                .setOverrideOutputAudioPort(configuration.overrideOutputAudioPort ?? .none)
            )
        ])

        if ownCapabilities.contains(.sendAudio) {
            actions.append(.setShouldRecord(true))
            actions.append(.setMicrophoneMuted(!callSettings.audioOn))
        } else {
            actions.append(.setShouldRecord(false))
            actions.append(.setMicrophoneMuted(true))
        }

        audioStore.dispatch(
            actions,
            file: file,
            function: function,
            line: line
        )
        lastAppliedConfiguration = configuration
        lastCallSettings = callSettings
        lastOwnCapabilities = ownCapabilities
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
