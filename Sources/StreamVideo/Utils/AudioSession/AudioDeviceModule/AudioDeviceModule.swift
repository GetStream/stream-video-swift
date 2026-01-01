//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AudioToolbox
import AVFAudio
import AVFoundation
import Combine
import Foundation
import StreamWebRTC

/// Bridges `RTCAudioDeviceModule` callbacks to Combine-based state so the
/// audio pipeline can stay in sync with application logic.
final class AudioDeviceModule: NSObject, RTCAudioDeviceModuleDelegate, Encodable, @unchecked Sendable {

    /// Helper constants used across the module.
    enum Constant {
        /// WebRTC interfaces return integer result codes. We use this typed/named
        /// constant to define the success of an operation.
        static let successResult = 0

        /// Audio pipeline floor in dB that we interpret as silence.
        static let silenceDB: Float = -160
    }

    /// Events emitted as the underlying audio engine changes state.
    enum Event: Equatable, CustomStringConvertible {
        /// Outbound audio surpassed the silence threshold.
        case speechActivityStarted
        /// Outbound audio dropped back to silence.
        case speechActivityEnded
        /// A new `AVAudioEngine` instance has been created.
        case didCreateAudioEngine(AVAudioEngine)
        /// The engine is about to enable playout/recording paths.
        case willEnableAudioEngine(AVAudioEngine, isPlayoutEnabled: Bool, isRecordingEnabled: Bool)
        /// The engine is about to start rendering.
        case willStartAudioEngine(AVAudioEngine, isPlayoutEnabled: Bool, isRecordingEnabled: Bool)
        /// The engine has fully stopped.
        case didStopAudioEngine(AVAudioEngine, isPlayoutEnabled: Bool, isRecordingEnabled: Bool)
        /// The engine was disabled after stopping.
        case didDisableAudioEngine(AVAudioEngine, isPlayoutEnabled: Bool, isRecordingEnabled: Bool)
        /// The engine will be torn down.
        case willReleaseAudioEngine(AVAudioEngine)
        /// The input graph is configured with a new source node.
        case configureInputFromSource(AVAudioEngine, source: AVAudioNode?, destination: AVAudioNode, format: AVAudioFormat)
        /// The output graph is configured with a destination node.
        case configureOutputFromSource(AVAudioEngine, source: AVAudioNode, destination: AVAudioNode?, format: AVAudioFormat)
        /// Voice processing knobs changed.
        case didUpdateAudioProcessingState(
            voiceProcessingEnabled: Bool,
            voiceProcessingBypassed: Bool,
            voiceProcessingAGCEnabled: Bool,
            stereoPlayoutEnabled: Bool
        )

        var description: String {
            switch self {
            case .speechActivityStarted:
                return ".speechActivityStarted"

            case .speechActivityEnded:
                return ".speechActivityEnded"

            case .didCreateAudioEngine(let engine):
                return ".didCreateAudioEngine(\(engine))"

            case .willEnableAudioEngine(let engine, let isPlayoutEnabled, let isRecordingEnabled):
                return ".willEnableAudioEngine(\(engine), isPlayoutEnabled:\(isPlayoutEnabled), isRecordingEnabled:\(isRecordingEnabled))"

            case .willStartAudioEngine(let engine, let isPlayoutEnabled, let isRecordingEnabled):
                return ".willStartAudioEngine(\(engine), isPlayoutEnabled:\(isPlayoutEnabled), isRecordingEnabled:\(isRecordingEnabled))"

            case .didStopAudioEngine(let engine, let isPlayoutEnabled, let isRecordingEnabled):
                return ".didStopAudioEngine(\(engine), isPlayoutEnabled:\(isPlayoutEnabled), isRecordingEnabled:\(isRecordingEnabled))"

            case .didDisableAudioEngine(let engine, let isPlayoutEnabled, let isRecordingEnabled):
                return ".didDisableAudioEngine(\(engine), isPlayoutEnabled:\(isPlayoutEnabled), isRecordingEnabled:\(isRecordingEnabled))"

            case .willReleaseAudioEngine(let engine):
                return ".willReleaseAudioEngine(\(engine))"

            case .configureInputFromSource(let engine, let source, let destination, let format):
                return ".configureInputFromSource(\(engine), source:\(source), destination:\(destination), format:\(format))"

            case .configureOutputFromSource(let engine, let source, let destination, let format):
                return ".configureOutputFromSource(\(engine), source:\(source), destination:\(destination), format:\(format))"

            case let .didUpdateAudioProcessingState(
                voiceProcessingEnabled,
                voiceProcessingBypassed,
                voiceProcessingAGCEnabled,
                stereoPlayoutEnabled
            ):
                return ".didUpdateAudioProcessingState(voiceProcessingEnabled:\(voiceProcessingEnabled), voiceProcessingBypassed:\(voiceProcessingBypassed), voiceProcessingAGCEnabled:\(voiceProcessingAGCEnabled), stereoPlayoutEnabled:\(stereoPlayoutEnabled))"
            }
        }
    }

    private struct AudioBufferInjectionPreState {
        var isAdvancedDuckingEnabled: Bool
        var duckingLevel: Int
        var isVoiceProcessingBypassed: Bool
        var isVoiceProcessingEnabled: Bool
        var isVoiceProcessingAGCEnabled: Bool
    }

    /// Tracks whether WebRTC is currently playing back audio.
    private let isPlayingSubject: CurrentValueSubject<Bool, Never>
    /// `true` while audio playout is active.
    var isPlaying: Bool { isPlayingSubject.value }
    /// Publisher that reflects playout activity changes.
    var isPlayingPublisher: AnyPublisher<Bool, Never> { isPlayingSubject.eraseToAnyPublisher() }

    /// Tracks whether WebRTC is capturing microphone samples.
    private let isRecordingSubject: CurrentValueSubject<Bool, Never>
    /// `true` while audio capture is active.
    var isRecording: Bool { isRecordingSubject.value }
    /// Publisher that reflects recording activity changes.
    var isRecordingPublisher: AnyPublisher<Bool, Never> { isRecordingSubject.eraseToAnyPublisher() }

    /// Tracks whether the microphone is muted at the ADM layer.
    private let isMicrophoneMutedSubject: CurrentValueSubject<Bool, Never>
    /// `true` if the microphone is muted.
    var isMicrophoneMuted: Bool { isMicrophoneMutedSubject.value }
    /// Publisher that reflects microphone mute changes.
    var isMicrophoneMutedPublisher: AnyPublisher<Bool, Never> { isMicrophoneMutedSubject.eraseToAnyPublisher() }

    /// Tracks whether stereo playout is configured.
    private let isStereoPlayoutEnabledSubject: CurrentValueSubject<Bool, Never>
    /// `true` if stereo playout is available and active.
    var isStereoPlayoutEnabled: Bool { isStereoPlayoutEnabledSubject.value }
    /// Publisher emitting stereo playout state.
    var isStereoPlayoutEnabledPublisher: AnyPublisher<Bool, Never> { isStereoPlayoutEnabledSubject.eraseToAnyPublisher() }

    /// Tracks whether VP processing is currently bypassed.
    private let isVoiceProcessingBypassedSubject: CurrentValueSubject<Bool, Never>
    /// `true` if the voice processing unit is bypassed.
    var isVoiceProcessingBypassed: Bool { isVoiceProcessingBypassedSubject.value }
    /// Publisher emitting VP bypass changes.
    var isVoiceProcessingBypassedPublisher: AnyPublisher<Bool, Never> { isVoiceProcessingBypassedSubject.eraseToAnyPublisher() }

    /// Tracks whether voice processing is enabled.
    private let isVoiceProcessingEnabledSubject: CurrentValueSubject<Bool, Never>
    /// `true` when Apple VP is active.
    var isVoiceProcessingEnabled: Bool { isVoiceProcessingEnabledSubject.value }
    /// Publisher emitting VP enablement changes.
    var isVoiceProcessingEnabledPublisher: AnyPublisher<Bool, Never> { isVoiceProcessingEnabledSubject.eraseToAnyPublisher() }

    /// Tracks whether automatic gain control is enabled inside VP.
    private let isVoiceProcessingAGCEnabledSubject: CurrentValueSubject<Bool, Never>
    /// `true` while AGC is active.
    var isVoiceProcessingAGCEnabled: Bool { isVoiceProcessingAGCEnabledSubject.value }
    /// Publisher emitting AGC changes.
    var isVoiceProcessingAGCEnabledPublisher: AnyPublisher<Bool, Never> { isVoiceProcessingAGCEnabledSubject.eraseToAnyPublisher() }

    /// Observes RMS audio levels (in dB) derived from the input tap.
    private let audioLevelSubject = CurrentValueSubject<Float, Never>(Constant.silenceDB) // default to silence
    /// Latest measured audio level.
    var audioLevel: Float { audioLevelSubject.value }
    /// Publisher emitting audio level updates.
    var audioLevelPublisher: AnyPublisher<Float, Never> { audioLevelSubject.eraseToAnyPublisher() }

    /// Wrapper around WebRTC `RTCAudioDeviceModule`.
    private let source: any RTCAudioDeviceModuleControlling
    /// Manages Combine subscriptions generated by this module.
    private let disposableBag: DisposableBag = .init()

    /// Serial queue used to deliver events to observers.
    private let dispatchQueue: DispatchQueue
    /// Internal relay that feeds `publisher`.
    private let subject: PassthroughSubject<Event, Never>
    /// Object that taps engine nodes and publishes audio level data.
    private var audioLevelsAdapter: AudioEngineNodeAdapting
    /// Public stream of `Event` values describing engine transitions.
    let publisher: AnyPublisher<Event, Never>

    /// Strong reference to the current engine so we can introspect it if needed.
    private var engine: AVAudioEngine?
    @Atomic private var engineInputContext: AVAudioEngine.InputContext? {
        didSet { audioBufferRenderer.configure(with: engineInputContext) }
    }

    private let audioBufferRenderer: AudioBufferRenderer = .init()

    private var preAudioBufferInjectionSnapshot: AudioBufferInjectionPreState?

    /// Textual diagnostics for logging and debugging.
    override var description: String {
        "{ " +
            "isPlaying:\(isPlaying)" +
            ", isRecording:\(isRecording)" +
            ", isMicrophoneMuted:\(isMicrophoneMuted)" +
            ", isStereoPlayoutEnabled:\(isStereoPlayoutEnabled)" +
            ", isVoiceProcessingBypassed:\(isVoiceProcessingBypassed)" +
            ", isVoiceProcessingEnabled:\(isVoiceProcessingEnabled)" +
            ", isVoiceProcessingAGCEnabled:\(isVoiceProcessingAGCEnabled)" +
            ", audioLevel:\(audioLevel)" +
            ", source:\(source)" +
            " }"
    }

    /// Creates a module that mirrors the provided WebRTC audio device module.
    /// - Parameter source: The audio device module implementation to observe.
    init(
        _ source: any RTCAudioDeviceModuleControlling,
        audioLevelsNodeAdapter: AudioEngineNodeAdapting = AudioEngineLevelNodeAdapter()
    ) {
        self.source = source
        self.isPlayingSubject = .init(source.isPlaying)
        self.isRecordingSubject = .init(source.isRecording)
        self.isMicrophoneMutedSubject = .init(source.isMicrophoneMuted)
        self.isStereoPlayoutEnabledSubject = .init(source.isStereoPlayoutEnabled)
        self.isVoiceProcessingBypassedSubject = .init(source.isVoiceProcessingBypassed)
        self.isVoiceProcessingEnabledSubject = .init(source.isVoiceProcessingEnabled)
        self.isVoiceProcessingAGCEnabledSubject = .init(source.isVoiceProcessingAGCEnabled)
        self.audioLevelsAdapter = audioLevelsNodeAdapter

        let dispatchQueue = DispatchQueue(label: "io.getstream.audiodevicemodule", qos: .userInteractive)
        let subject = PassthroughSubject<Event, Never>()
        self.subject = subject
        self.dispatchQueue = dispatchQueue
        self.publisher = subject
            .receive(on: dispatchQueue)
            .eraseToAnyPublisher()
        super.init()

        subject
            .log(.debug, subsystems: .audioSession) { "\($0)" }
            .sink { _ in }
            .store(in: disposableBag)

        audioLevelsAdapter.subject = audioLevelSubject
        source.observer = self
    }

    // MARK: - Recording

    /// Reinitializes the ADM, clearing its internal audio graph state.
    func reset() {
        _ = source.reset()
    }

    /// Switches between stereo and mono playout while keeping the recording
    /// state consistent across reinitializations.
    /// - Parameter isPreferred: `true` when stereo output should be used.
    func setStereoPlayoutPreference(_ isPreferred: Bool) {
        /// - Important: `.voiceProcessing` requires VP to be enabled in order to mute and
        /// `.restartEngine` rebuilds the whole graph. Each of them has different issues:
        /// - `.voiceProcessing`: as it requires VP to be enabled in order to mute/unmute that
        /// means that for outputs where VP is disabled (e.g. stereo) we cannot mute/unmute.
        /// - `.restartEngine`: rebuilds the whole graph and requires explicit calling of
        /// `initAndStartRecording` .
        _ = source.setMuteMode(isPreferred ? .inputMixer : .voiceProcessing)
        /// - Important: We can probably set this one to false when the user doesn't have
        /// sendAudio capability.
        _ = source.setRecordingAlwaysPreparedMode(false)
        source.prefersStereoPlayout = isPreferred
        source.isVoiceProcessingBypassed = isPreferred
    }

    /// Starts or stops speaker playout on the ADM, retrying transient failures.
    /// - Parameter isActive: `true` to start playout, `false` to stop.
    /// - Throws: `ClientError` when WebRTC returns a non-zero status.
    func setPlayout(_ isActive: Bool) throws {
        guard isActive != isPlaying else {
            return
        }
        if isActive {
            if source.isPlayoutInitialized {
                try throwingExecution("Unable to start playout") {
                    source.startPlayout()
                }
            } else {
                try throwingExecution("Unable to initAndStart playout") {
                    source.initAndStartPlayout()
                }
            }
        } else {
            try throwingExecution("Unable to stop playout") {
                source.stopPlayout()
            }
        }
    }

    /// Enables or disables recording on the wrapped audio device module.
    /// - Parameter isEnabled: When `true` recording starts, otherwise stops.
    /// - Throws: `ClientError` when the underlying module reports a failure.
    func setRecording(_ isEnabled: Bool) throws {
        guard isEnabled != isRecording else {
            return
        }
        if isEnabled {
            if source.isRecordingInitialized {
                try throwingExecution("Unable to start recording") {
                    source.startRecording()
                }
            } else {
                try throwingExecution("Unable to initAndStart recording") {
                    source.initAndStartRecording()
                }
            }
        } else {
            try throwingExecution("Unable to stop recording") {
                source.stopRecording()
            }
        }

        isRecordingSubject.send(isEnabled)
    }

    /// Updates the muted state of the microphone for the wrapped module.
    /// - Parameter isMuted: `true` to mute the microphone, `false` to unmute.
    /// - Throws: `ClientError` when the underlying module reports a failure.
    func setMuted(_ isMuted: Bool) throws {
        guard isMuted != source.isMicrophoneMuted else {
            return
        }

        if !isMuted, !isRecording {
            try setRecording(true)
        }

        try throwingExecution("Unable to setMicrophoneMuted:\(isMuted)") {
            source.setMicrophoneMuted(isMuted)
        }

        isMicrophoneMutedSubject.send(isMuted)
    }

    /// Forces the ADM to recompute whether stereo output is supported.
    func refreshStereoPlayoutState() {
        source.refreshStereoPlayoutState()
    }

    // MARK: - Audio Buffer injection

    /// Enqueues a screen share audio sample buffer for playback.
    func enqueue(_ sampleBuffer: CMSampleBuffer) {
        audioBufferRenderer.enqueue(sampleBuffer)
    }

    // MARK: - RTCAudioDeviceModuleDelegate

    /// Receives speech activity notifications emitted by WebRTC VAD.
    func audioDeviceModule(
        _ audioDeviceModule: RTCAudioDeviceModule,
        didReceiveSpeechActivityEvent speechActivityEvent: RTCSpeechActivityEvent
    ) {
        switch speechActivityEvent {
        case .started:
            subject.send(.speechActivityStarted)
        case .ended:
            subject.send(.speechActivityEnded)
        @unknown default:
            break
        }
    }

    /// Stores the created engine reference and emits an event so observers can
    /// hook into the audio graph configuration.
    func audioDeviceModule(
        _ audioDeviceModule: RTCAudioDeviceModule,
        didCreateEngine engine: AVAudioEngine
    ) -> Int {
        self.engine = engine
        subject.send(.didCreateAudioEngine(engine))
        return Constant.successResult
    }

    /// Keeps local playback/recording state in sync as WebRTC enables the
    /// corresponding engine paths.
    func audioDeviceModule(
        _ audioDeviceModule: RTCAudioDeviceModule,
        willEnableEngine engine: AVAudioEngine,
        isPlayoutEnabled: Bool,
        isRecordingEnabled: Bool
    ) -> Int {
        subject.send(
            .willEnableAudioEngine(
                engine,
                isPlayoutEnabled: isPlayoutEnabled,
                isRecordingEnabled: isRecordingEnabled
            )
        )
        isPlayingSubject.send(isPlayoutEnabled)
        isRecordingSubject.send(isRecordingEnabled)
        return Constant.successResult
    }

    /// Mirrors state when the engine is about to start running and delivering
    /// audio samples.
    func audioDeviceModule(
        _ audioDeviceModule: RTCAudioDeviceModule,
        willStartEngine engine: AVAudioEngine,
        isPlayoutEnabled: Bool,
        isRecordingEnabled: Bool
    ) -> Int {
        subject.send(
            .willStartAudioEngine(
                engine,
                isPlayoutEnabled: isPlayoutEnabled,
                isRecordingEnabled: isRecordingEnabled
            )
        )
        isPlayingSubject.send(isPlayoutEnabled)
        isRecordingSubject.send(isRecordingEnabled)

        return Constant.successResult
    }

    /// Updates state and notifies observers once the engine has completely
    /// stopped.
    func audioDeviceModule(
        _ audioDeviceModule: RTCAudioDeviceModule,
        didStopEngine engine: AVAudioEngine,
        isPlayoutEnabled: Bool,
        isRecordingEnabled: Bool
    ) -> Int {
        subject.send(
            .didStopAudioEngine(
                engine,
                isPlayoutEnabled: isPlayoutEnabled,
                isRecordingEnabled: isRecordingEnabled
            )
        )
        isPlayingSubject.send(isPlayoutEnabled)
        isRecordingSubject.send(isRecordingEnabled)
        audioBufferRenderer.reset()
        return Constant.successResult
    }

    /// Tracks when the engine has been disabled after stopping so clients can
    /// react (e.g., rebuilding audio graphs).
    func audioDeviceModule(
        _ audioDeviceModule: RTCAudioDeviceModule,
        didDisableEngine engine: AVAudioEngine,
        isPlayoutEnabled: Bool,
        isRecordingEnabled: Bool
    ) -> Int {
        subject.send(
            .didDisableAudioEngine(
                engine,
                isPlayoutEnabled: isPlayoutEnabled,
                isRecordingEnabled: isRecordingEnabled
            )
        )
        isPlayingSubject.send(isPlayoutEnabled)
        isRecordingSubject.send(isRecordingEnabled)
        audioBufferRenderer.reset()
        engineInputContext = nil
        return Constant.successResult
    }

    /// Clears internal references before WebRTC disposes the engine.
    func audioDeviceModule(
        _ audioDeviceModule: RTCAudioDeviceModule,
        willReleaseEngine engine: AVAudioEngine
    ) -> Int {
        self.engine = nil
        subject.send(.willReleaseAudioEngine(engine))
        audioLevelsAdapter.uninstall(on: 0)
        audioBufferRenderer.reset()
        engineInputContext = nil
        return Constant.successResult
    }

    /// Keeps observers informed when WebRTC sets up the input graph and installs
    /// an audio level tap to monitor microphone activity.
    func audioDeviceModule(
        _ audioDeviceModule: RTCAudioDeviceModule,
        engine: AVAudioEngine,
        configureInputFromSource source: AVAudioNode?,
        toDestination destination: AVAudioNode,
        format: AVAudioFormat,
        context: [AnyHashable: Any]
    ) -> Int {
        engineInputContext = .init(
            engine: engine,
            source: source,
            destination: destination,
            format: format
        )

        subject.send(
            .configureInputFromSource(
                engine,
                source: source,
                destination: destination,
                format: format
            )
        )

        audioLevelsAdapter.installInputTap(
            on: destination,
            format: format,
            bus: 0,
            bufferSize: 1024
        )

        return Constant.successResult
    }

    /// Emits an event whenever WebRTC reconfigures the output graph.
    func audioDeviceModule(
        _ audioDeviceModule: RTCAudioDeviceModule,
        engine: AVAudioEngine,
        configureOutputFromSource source: AVAudioNode,
        toDestination destination: AVAudioNode?,
        format: AVAudioFormat,
        context: [AnyHashable: Any]
    ) -> Int {
        subject.send(
            .configureOutputFromSource(
                engine,
                source: source,
                destination: destination,
                format: format
            )
        )
        return Constant.successResult
    }

    /// Currently unused: CallKit/RoutePicker own the device selection UX.
    func audioDeviceModuleDidUpdateDevices(
        _ audioDeviceModule: RTCAudioDeviceModule
    ) {
        // No-op
    }

    /// Mirrors state changes coming from CallKit/WebRTC voice-processing
    /// controls so UI can reflect the correct toggles.
    func audioDeviceModule(
        _ module: RTCAudioDeviceModule,
        didUpdateAudioProcessingState state: RTCAudioProcessingState
    ) {
        subject.send(
            .didUpdateAudioProcessingState(
                voiceProcessingEnabled: state.voiceProcessingEnabled,
                voiceProcessingBypassed: state.voiceProcessingBypassed,
                voiceProcessingAGCEnabled: state.voiceProcessingAGCEnabled,
                stereoPlayoutEnabled: state.stereoPlayoutEnabled
            )
        )
        isVoiceProcessingEnabledSubject.send(state.voiceProcessingEnabled)
        isVoiceProcessingBypassedSubject.send(state.voiceProcessingBypassed)
        isVoiceProcessingAGCEnabledSubject.send(state.voiceProcessingAGCEnabled)
        isStereoPlayoutEnabledSubject.send(state.stereoPlayoutEnabled)
    }

    /// Mirrors the subset of properties that can be encoded for debugging.
    private enum CodingKeys: String, CodingKey {
        case isPlaying
        case isRecording
        case isMicrophoneMuted
        case isStereoPlayoutEnabled
        case isVoiceProcessingBypassed
        case isVoiceProcessingEnabled
        case isVoiceProcessingAGCEnabled

        case audioLevel
    }

    /// Serializes the module state, primarily for diagnostic payloads.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isPlaying, forKey: .isPlaying)
        try container.encode(isRecording, forKey: .isRecording)
        try container.encode(isMicrophoneMuted, forKey: .isMicrophoneMuted)
        try container.encode(isStereoPlayoutEnabled, forKey: .isStereoPlayoutEnabled)
        try container.encode(isVoiceProcessingBypassed, forKey: .isVoiceProcessingBypassed)
        try container.encode(isVoiceProcessingEnabled, forKey: .isVoiceProcessingEnabled)
        try container.encode(isVoiceProcessingAGCEnabled, forKey: .isVoiceProcessingAGCEnabled)
        try container.encode(audioLevel, forKey: .audioLevel)
    }

    // MARK: - Private helpers

    /// Runs a WebRTC ADM call and translates its integer result into a
    /// `ClientError` enriched with call-site metadata.
    private func throwingExecution(
        _ message: @autoclosure () -> String,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line,
        _ operation: () -> Int
    ) throws {
        let result = operation()

        guard result != Constant.successResult else {
            return
        }

        throw ClientError(
            "\(message()) (Error code:\(result))",
            file,
            line
        )
    }
}
