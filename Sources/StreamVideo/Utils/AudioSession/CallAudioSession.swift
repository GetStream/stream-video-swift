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

    private var lastCallSettings: CallSettings?
    private var lastOwnCapabilities: Set<OwnCapability>?

    init(
        stereoPlayoutMode: StereoPlayoutMode = .externalOnly,
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
                    mode: .voiceChat,
                    categoryOptions: stereoPlayoutMode == .deviceAndExternal || stereoPlayoutMode == .externalOnly ?
                        [.allowBluetoothA2DP] : [
                            .allowBluetooth,
                            .allowBluetoothA2DP
                        ]
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

        audioStore
            .publisher(\.currentRoute)
            .removeDuplicates()
            // We want to start listening on route changes **once** we have
            // expressed our initial preference.
            .drop { [weak self] _ in self?.lastCallSettings == nil }
            .throttle(for: 0.5, scheduler: processingQueue, latest: true)
            .receive(on: processingQueue)
            .sink { [weak self] in
                guard let self, let lastCallSettings, let lastOwnCapabilities else { return }
                if lastCallSettings.speakerOn != $0.isSpeaker {
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

    private func didUpdate(
        callSettings: CallSettings,
        ownCapabilities: Set<OwnCapability>,
        currentRoute: RTCAudioStore.StoreState.AudioRoute
    ) {
        defer { statsAdapter?.trace(.init(audioSession: traceRepresentation)) }

        var configuration = policy.configuration(
            for: callSettings,
            ownCapabilities: ownCapabilities
        )
        .withStereoPlayoutMode(stereoPlayoutMode)

        let currentRoute = audioStore.state.currentRoute

        switch stereoPlayoutMode {
        case .none:
            break

        case .deviceOnly:
            if callSettings.speakerOn {
                configuration.mode = .default
            } else if currentRoute.isReceiver, currentRoute.supportsStereoOutput {
                configuration.mode = .default
            }

        case .externalOnly:
            if currentRoute.isExternal, currentRoute.supportsStereoOutput {
                configuration.mode = .default
            }

        case .deviceAndExternal:
            if callSettings.speakerOn {
                configuration.mode = .default
            } else if currentRoute.isReceiver, currentRoute.supportsStereoOutput {
                configuration.mode = .default
            } else if currentRoute.isExternal, currentRoute.supportsStereoOutput {
                configuration.mode = .default
            }
        }

        var actions: [RTCAudioStore.Namespace.Action] = []
        if callSettings.speakerOn {
            actions.append(.avAudioSession(.prepareForSpeakerTransition))
        }

        actions.append(contentsOf: [
            .avAudioSession(
                .setCategoryAndModeAndCategoryOptions(
                    configuration.category,
                    mode: configuration.mode,
                    categoryOptions: configuration.options
                )
            ),
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

        audioStore.dispatch(actions)
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
