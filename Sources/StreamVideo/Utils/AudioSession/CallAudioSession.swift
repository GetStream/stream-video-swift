//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation

/// `CallAudioSession` manages the audio session for calls, handling configuration,
/// activation, and deactivation.
final class CallAudioSession: @unchecked Sendable {

    @Injected(\.audioStore) private var audioStore

    /// Bundles the reactive inputs we need to evaluate whenever call
    /// capabilities or settings change, keeping log context attached.
    private struct Input {
        var callSettings: CallSettings
        var ownCapabilities: Set<OwnCapability>
        var currentRoute: RTCAudioStore.StoreState.AudioRoute?
        var file: StaticString
        var function: StaticString
        var line: UInt

        init(
            callSettings: CallSettings,
            ownCapabilities: Set<OwnCapability>,
            currentRoute: RTCAudioStore.StoreState.AudioRoute? = nil,
            file: StaticString = #file,
            function: StaticString = #function,
            line: UInt = #line
        ) {
            self.callSettings = callSettings
            self.ownCapabilities = ownCapabilities
            self.currentRoute = currentRoute
            self.file = file
            self.function = function
            self.line = line
        }
    }

    var currentRouteIsExternal: Bool { audioStore.state.currentRoute.isExternal }

    private(set) weak var delegate: StreamAudioSessionAdapterDelegate?
    private(set) var statsAdapter: WebRTCStatsAdapting?

    /// The current audio session policy used to configure the session.
    /// Determines audio behaviour for the call session.
    /// Set this property to change how the session is configured.
    @Atomic private(set) var policy: AudioSessionPolicy

    private let disposableBag = DisposableBag()
    private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)

    /// Serialises policy evaluations so the AVAudioSession only receives one
    /// configuration at a time even when upstream publishers fire in bursts.
    private let processingPipeline = PassthroughSubject<Input, Never>()

    private var lastAppliedConfiguration: AudioSessionConfiguration?
    private var lastCallSettings: CallSettings?
    private var lastOwnCapabilities: Set<OwnCapability>?

    init(policy: AudioSessionPolicy = DefaultAudioSessionPolicy()) {
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

        processingPipeline
            .debounce(for: .milliseconds(250), scheduler: processingQueue)
            .receive(on: processingQueue)
            .sink { [weak self] in self?.process($0) }
            .store(in: disposableBag)

        self.delegate = delegate
        self.statsAdapter = statsAdapter

        // Expose the policy's stereo preference so the audio device module can
        // reconfigure itself before WebRTC starts playout.
        audioStore.dispatch(.stereo(.setPlayoutPreferred(policy is LivestreamAudioSessionPolicy)))

        configureCallSettingsAndCapabilitiesObservation(
            callSettingsPublisher: callSettingsPublisher,
            ownCapabilitiesPublisher: ownCapabilitiesPublisher
        )
        configureCurrentRouteObservation()
        configureCallOptionsObservation()

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

        processingPipeline.send(
            .init(
                callSettings: callSettings,
                ownCapabilities: ownCapabilities,
                currentRoute: audioStore.state.currentRoute
            )
        )
    }

    // MARK: - Private Helpers

    private func process(
        _ input: Input
    ) {
        log.debug(
            "⚙️ Processing input:\(input).",
            functionName: input.function,
            fileName: input.file,
            lineNumber: input.line
        )
        didUpdate(
            callSettings: input.callSettings,
            ownCapabilities: input.ownCapabilities,
            currentRoute: input.currentRoute ?? audioStore.state.currentRoute,
            file: input.file,
            function: input.function,
            line: input.line
        )
    }

    /// Wires call setting and capability updates into the processing queue so
    /// downstream work always executes serially.
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

                processingPipeline.send(
                    .init(
                        callSettings: $0,
                        ownCapabilities: $1
                    )
                )
            }
            .store(in: disposableBag)
    }

    /// Reapplies the last known category options when the system clears them,
    /// which happens after some CallKit activations.
    private func configureCallOptionsObservation() {
        audioStore
            .publisher(\.audioSessionConfiguration.options)
            .removeDuplicates()
            .filter { $0.isEmpty }
            .receive(on: processingQueue)
            .compactMap { [weak self] _ in self?.lastAppliedConfiguration?.options }
            .sink { [weak self] in self?.audioStore.dispatch(.avAudioSession(.setCategoryOptions($0))) }
            .store(in: disposableBag)
    }

    /// Keeps the delegate informed of hardware flips while also re-evaluating
    /// the policy when we detect a reconfiguration-worthy route change.
    private func configureCurrentRouteObservation() {
        audioStore
            .publisher(\.currentRoute)
            .removeDuplicates()
            .filter { $0.reason.requiresReconfiguration }
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
                    processingPipeline.send(
                        .init(
                            callSettings: lastCallSettings,
                            ownCapabilities: lastOwnCapabilities,
                            currentRoute: $0
                        )
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

        applyConfiguration(
            policy.configuration(
                for: callSettings,
                ownCapabilities: ownCapabilities
            ),
            callSettings: callSettings,
            ownCapabilities: ownCapabilities,
            file: file,
            function: function,
            line: line
        )
    }

    /// Breaks the configuration into store actions so reducers update the
    /// audio session and our own bookkeeping in a single dispatch.
    private func applyConfiguration(
        _ configuration: AudioSessionConfiguration,
        callSettings: CallSettings,
        ownCapabilities: Set<OwnCapability>,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        log.debug(
            "CallAudioSession will apply configuration:\(configuration)",
            subsystems: .audioSession,
            functionName: function,
            fileName: file,
            lineNumber: line
        )

        var actions: [StoreActionBox<RTCAudioStore.Namespace.Action>] = []

        actions.append(.normal(.setMicrophoneMuted(!callSettings.audioOn || !ownCapabilities.contains(.sendAudio))))

        actions.append(
            .normal(
                .avAudioSession(
                    .setCategoryAndModeAndCategoryOptions(
                        configuration.category,
                        mode: configuration.mode,
                        categoryOptions: configuration.options
                    )
                )
            )
        )

        actions.append(contentsOf: [
            // Setting only the audioEnabled doesn't stop the audio playout
            // as if a new track gets added later on WebRTC will try to restart
            // the playout. However, the combination of audioEnabled:false
            // and AVAudioSession.active:false seems to work.
            .normal(.webRTCAudioSession(.setAudioEnabled(configuration.isActive))),
            .normal(.setActive(configuration.isActive)),
            .normal(.avAudioSession(.setOverrideOutputAudioPort(configuration.overrideOutputAudioPort ?? .none)))
        ])

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
