//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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

    enum Constant {
        // WebRTC interfaces are returning integer result codes. We use this typed/named
        // constant to define the Success of an operation.
        static let successResult = 0

        // The down limit of audio pipeline in DB that is considered silence.
        static let silenceDB: Float = -160
    }

    /// Events emitted as the underlying audio engine changes state.
    enum Event: Equatable, CustomStringConvertible {
        case speechActivityStarted
        case speechActivityEnded
        case didCreateAudioEngine(AVAudioEngine)
        case willEnableAudioEngine(AVAudioEngine, isPlayoutEnabled: Bool, isRecordingEnabled: Bool)
        case willStartAudioEngine(AVAudioEngine, isPlayoutEnabled: Bool, isRecordingEnabled: Bool)
        case didStopAudioEngine(AVAudioEngine, isPlayoutEnabled: Bool, isRecordingEnabled: Bool)
        case didDisableAudioEngine(AVAudioEngine, isPlayoutEnabled: Bool, isRecordingEnabled: Bool)
        case willReleaseAudioEngine(AVAudioEngine)
        case configureInputFromSource(AVAudioEngine, source: AVAudioNode?, destination: AVAudioNode, format: AVAudioFormat)
        case configureOutputFromSource(AVAudioEngine, source: AVAudioNode, destination: AVAudioNode?, format: AVAudioFormat)

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
            }
        }
    }

    private let isPlayingSubject: CurrentValueSubject<Bool, Never>
    var isPlaying: Bool { isPlayingSubject.value }
    var isPlayingPublisher: AnyPublisher<Bool, Never> { isPlayingSubject.eraseToAnyPublisher() }

    private let isRecordingSubject: CurrentValueSubject<Bool, Never>
    var isRecording: Bool { isRecordingSubject.value }
    var isRecordingPublisher: AnyPublisher<Bool, Never> { isRecordingSubject.eraseToAnyPublisher() }

    private let isMicrophoneMutedSubject: CurrentValueSubject<Bool, Never>
    var isMicrophoneMuted: Bool { isMicrophoneMutedSubject.value }
    var isMicrophoneMutedPublisher: AnyPublisher<Bool, Never> { isMicrophoneMutedSubject.eraseToAnyPublisher() }

    private let isStereoPlayoutEnabledSubject: CurrentValueSubject<Bool, Never>
    var isStereoPlayoutEnabled: Bool { isStereoPlayoutEnabledSubject.value }
    var isStereoPlayoutEnabledPublisher: AnyPublisher<Bool, Never> { isStereoPlayoutEnabledSubject.eraseToAnyPublisher() }

    private let isVoiceProcessingBypassedSubject: CurrentValueSubject<Bool, Never>
    var isVoiceProcessingBypassed: Bool { isVoiceProcessingBypassedSubject.value }
    var isVoiceProcessingBypassedPublisher: AnyPublisher<Bool, Never> { isVoiceProcessingBypassedSubject.eraseToAnyPublisher() }

    private let isVoiceProcessingEnabledSubject: CurrentValueSubject<Bool, Never>
    var isVoiceProcessingEnabled: Bool { isVoiceProcessingEnabledSubject.value }
    var isVoiceProcessingEnabledPublisher: AnyPublisher<Bool, Never> { isVoiceProcessingEnabledSubject.eraseToAnyPublisher() }

    private let isVoiceProcessingAGCEnabledSubject: CurrentValueSubject<Bool, Never>
    var isVoiceProcessingAGCEnabled: Bool { isVoiceProcessingAGCEnabledSubject.value }
    var isVoiceProcessingAGCEnabledPublisher: AnyPublisher<Bool, Never> { isVoiceProcessingAGCEnabledSubject.eraseToAnyPublisher() }

    private let audioLevelSubject = CurrentValueSubject<Float, Never>(Constant.silenceDB) // default to silence
    var audioLevel: Float { audioLevelSubject.value }
    var audioLevelPublisher: AnyPublisher<Float, Never> { audioLevelSubject.eraseToAnyPublisher() }

    private let source: any RTCAudioDeviceModuleControlling
    private let disposableBag: DisposableBag = .init()

    private let dispatchQueue: DispatchQueue
    private let subject: PassthroughSubject<Event, Never>
    private var audioLevelsAdapter: AudioEngineNodeAdapting
    let publisher: AnyPublisher<Event, Never>

    private var engine: AVAudioEngine?

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
            ", engineOutput: \(engine?.outputDescription ?? "-")" +
            " }"
    }

    /// Creates a module that mirrors the provided WebRTC audio device module.
    /// - Parameter source: The audio device module implementation to observe.
    init(
        _ source: any RTCAudioDeviceModuleControlling,
        isPlaying: Bool = false,
        isRecording: Bool = false,
        isMicrophoneMuted: Bool = false,
        audioLevelsNodeAdapter: AudioEngineNodeAdapting = AudioEngineLevelNodeAdapter()
    ) {
        self.source = source
        self.isPlayingSubject = .init(isPlaying)
        self.isRecordingSubject = .init(isRecording)
        self.isMicrophoneMutedSubject = .init(isMicrophoneMuted)
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

        source
            .microphoneMutedPublisher()
            .receive(on: dispatchQueue)
            .sink { [weak self] in self?.isMicrophoneMutedSubject.send($0) }
            .store(in: disposableBag)

        source
            .isVoiceProcessingBypassedPublisher()
            .receive(on: dispatchQueue)
            .sink { [weak self] in self?.isVoiceProcessingBypassedSubject.send($0) }
            .store(in: disposableBag)
        source
            .isVoiceProcessingEnabledPublisher()
            .receive(on: dispatchQueue)
            .sink { [weak self] in self?.isVoiceProcessingEnabledSubject.send($0) }
            .store(in: disposableBag)
        source
            .isVoiceProcessingAGCEnabledPublisher()
            .receive(on: dispatchQueue)
            .sink { [weak self] in self?.isVoiceProcessingAGCEnabledSubject.send($0) }
            .store(in: disposableBag)
    }

    // MARK: - Recording

    func terminate() {
        _ = source.terminate()
    }

    func setStereoPlayoutPreference(_ isPreferred: Bool) {
        /// - Important: `.voiceProcessing` requires VP to be enabled in order to mute and
        /// `.restartEngine` rebuilds the whole graph. Each of them has different issues:
        /// - `.voiceProcessing`: as it requires VP to be enabled in order to mute/unmute that
        /// means that for outputs where VP is disabled (e.g. stereo) we cannot mute/unmute.
        /// - `.restartEngine`: rebuilds the whole graph and requires explicit calling of
        /// `initAndStartRecording` .
        (source as? RTCAudioDeviceModule)?.setMuteMode(
            isPreferred ? .inputMixer : .voiceProcessing
        )
        /// - Important: We can probably set this one to false when the user doesn't have
        /// sendAudio capability.
        (source as? RTCAudioDeviceModule)?.setRecordingAlwaysPreparedMode(true)
        source.prefersStereoPlayout = isPreferred
        source.setManualRestoreVoiceProcessingOnMono(isPreferred)

        let isMuted = isMicrophoneMuted

        _ = source.stopRecording()
        _ = source.initAndStartRecording()
        if isMuted {
            _ = source.setMicrophoneMuted(isMuted)
        }
    }

    func setPlayout(_ isActive: Bool) throws {
        try RetriableTask.run(iterations: 3) {
            try throwingExecution("Unable to start playout") {
                if isActive {
                    return source.initAndStartPlayout()
                } else {
                    return source.stopPlayout()
                }
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
            let isMicrophoneMuted = source.isMicrophoneMuted

            try throwingExecution("Unable to initAndStartRecording.") {
                source.initAndStartRecording()
            }

            // After restarting the ADM it always returns with microphoneMute:false.
            // Here we reinstate the muted condition after restarting ADM.
            if isMicrophoneMuted {
                try throwingExecution("Unable to setMicrophoneMuted:\(isEnabled).") {
                    source.setMicrophoneMuted(isMicrophoneMuted)
                }
            }
        } else {
            try throwingExecution("Unable to stopRecording.") {
                source.stopRecording()
            }
        }

        isRecordingSubject.send(isEnabled)
    }

    /// Updates the muted state of the microphone for the wrapped module.
    /// - Parameter isMuted: `true` to mute the microphone, `false` to unmute.
    /// - Throws: `ClientError` when the underlying module reports a failure.
    func setMuted(_ isMuted: Bool) throws {
        guard isMuted != isMicrophoneMuted else {
            return
        }

        try throwingExecution("Unable to setMicrophoneMuted:\(isMuted)") {
            source.setMicrophoneMuted(isMuted)
        }

        isMicrophoneMutedSubject.send(isMuted)
    }

    func refreshStereoPlayoutState() {
        source.refreshStereoPlayoutState()
    }

    // MARK: - RTCAudioDeviceModuleDelegate

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

    func audioDeviceModule(
        _ audioDeviceModule: RTCAudioDeviceModule,
        didCreateEngine engine: AVAudioEngine
    ) -> Int {
        self.engine = engine
        subject.send(.didCreateAudioEngine(engine))
        return Constant.successResult
    }

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
        return Constant.successResult
    }

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
        return Constant.successResult
    }

    func audioDeviceModule(
        _ audioDeviceModule: RTCAudioDeviceModule,
        willReleaseEngine engine: AVAudioEngine
    ) -> Int {
        self.engine = nil
        subject.send(.willReleaseAudioEngine(engine))
        audioLevelsAdapter.uninstall(on: 0)
        return Constant.successResult
    }

    func audioDeviceModule(
        _ audioDeviceModule: RTCAudioDeviceModule,
        engine: AVAudioEngine,
        configureInputFromSource source: AVAudioNode?,
        toDestination destination: AVAudioNode,
        format: AVAudioFormat,
        context: [AnyHashable: Any]
    ) -> Int {
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

    func audioDeviceModuleDidUpdateDevices(
        _ audioDeviceModule: RTCAudioDeviceModule
    ) {
        // No-op
    }

    func audioDeviceModule(
        _ module: RTCAudioDeviceModule,
        didUpdateAudioProcessingState state: RTCAudioProcessingState
    ) {
        isVoiceProcessingEnabledSubject.send(state.voiceProcessingEnabled)
        isVoiceProcessingBypassedSubject.send(state.voiceProcessingBypassed)
        isVoiceProcessingAGCEnabledSubject.send(state.voiceProcessingAGCEnabled)
        isStereoPlayoutEnabledSubject.send(state.stereoPlayoutEnabled)
    }

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

extension AVAudioEngine {

    var outputDescription: String {
        guard let remoteIO = outputNode.audioUnit else {
            return "not available"
        }

        var asbd = AudioStreamBasicDescription()
        var size = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)

        let status = AudioUnitGetProperty(
            remoteIO,
            kAudioUnitProperty_StreamFormat,
            kAudioUnitScope_Output,
            0,
            &asbd,
            &size
        )

        guard status == noErr else {
            return "failed to fetch information"
        }

        return "\(asbd.mChannelsPerFrame) ch @ \(asbd.mSampleRate) Hz"
    }
}

enum RetriableTask {
    static func run(
        iterations: Int,
        operation: () throws -> Void
    ) throws {
        try execute(
            currentIteration: 0,
            iterations: iterations,
            operation: operation
        )
    }

    private static func execute(
        currentIteration: Int,
        iterations: Int,
        operation: () throws -> Void
    ) throws {
        do {
            return try operation()
        } catch {
            if currentIteration < iterations - 1 {
                do {
                    return try execute(
                        currentIteration: currentIteration + 1,
                        iterations: iterations,
                        operation: operation
                    )
                } catch {
                    throw error
                }
            } else {
                throw error
            }
        }
    }
}
