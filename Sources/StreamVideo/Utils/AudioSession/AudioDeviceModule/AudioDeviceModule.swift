//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
import StreamWebRTC

/// Bridges `RTCAudioDeviceModule` callbacks to Combine-based state so the
/// audio pipeline can stay in sync with application logic.
final class AudioDeviceModule: NSObject, RTCAudioDeviceModuleDelegate, Encodable, @unchecked Sendable {

    /// Events emitted as the underlying audio engine changes state.
    enum Event: Equatable {
        case speechActivityStarted
        case speechActivityEnded
        case didCreateAudioEngine(AVAudioEngine)
        case willEnableAudioEngine(AVAudioEngine)
        case willStartAudioEngine(AVAudioEngine)
        case didStopAudioEngine(AVAudioEngine)
        case didDisableAudioEngine(AVAudioEngine)
        case willReleaseAudioEngine(AVAudioEngine)
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

    private let audioLevelSubject = CurrentValueSubject<Float, Never>(-160) // default to silence
    var audioLevel: Float { audioLevelSubject.value }
    var audioLevelPublisher: AnyPublisher<Float, Never> { audioLevelSubject.eraseToAnyPublisher() }

    private let source: any RTCAudioDeviceModuleControlling
    private let disposableBag: DisposableBag = .init()

    private let dispatchQueue: DispatchQueue
    private let subject: PassthroughSubject<Event, Never>
    private var audioLevelsAdapter: AudioEngineNodeAdapting
    let publisher: AnyPublisher<Event, Never>

    override var description: String {
        "{ " +
            "isPlaying:\(isPlaying)" +
            ", isRecording:\(isRecording)" +
            ", isMicrophoneMuted:\(isMicrophoneMuted)" +
            ", audioLevel:\(audioLevel)" +
            ", source:\(source)" +
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
        self.audioLevelsAdapter = audioLevelsNodeAdapter

        let dispatchQueue = DispatchQueue(label: "io.getstream.audiodevicemodule", qos: .userInteractive)
        let subject = PassthroughSubject<Event, Never>()
        self.subject = subject
        self.dispatchQueue = dispatchQueue
        self.publisher = subject
            .receive(on: dispatchQueue)
            .eraseToAnyPublisher()
        super.init()

        audioLevelsAdapter.subject = audioLevelSubject
        source.observer = self

        source
            .microphoneMutedPublisher()
            .receive(on: dispatchQueue)
            .sink { [weak self] in self?.isMicrophoneMutedSubject.send($0) }
            .store(in: disposableBag)
    }

    // MARK: - Recording

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
        subject.send(.didCreateAudioEngine(engine))
        return 0
    }

    func audioDeviceModule(
        _ audioDeviceModule: RTCAudioDeviceModule,
        willEnableEngine engine: AVAudioEngine,
        isPlayoutEnabled: Bool,
        isRecordingEnabled: Bool
    ) -> Int {
        subject.send(.willEnableAudioEngine(engine))
        isPlayingSubject.send(isPlayoutEnabled)
        isRecordingSubject.send(isRecordingEnabled)
        return 0
    }

    func audioDeviceModule(
        _ audioDeviceModule: RTCAudioDeviceModule,
        willStartEngine engine: AVAudioEngine,
        isPlayoutEnabled: Bool,
        isRecordingEnabled: Bool
    ) -> Int {
        subject.send(.willStartAudioEngine(engine))
        isPlayingSubject.send(isPlayoutEnabled)
        isRecordingSubject.send(isRecordingEnabled)
        return 0
    }

    func audioDeviceModule(
        _ audioDeviceModule: RTCAudioDeviceModule,
        didStopEngine engine: AVAudioEngine,
        isPlayoutEnabled: Bool,
        isRecordingEnabled: Bool
    ) -> Int {
        subject.send(.didStopAudioEngine(engine))
        audioLevelsAdapter.uninstall(on: 0)
        isPlayingSubject.send(isPlayoutEnabled)
        isRecordingSubject.send(isRecordingEnabled)
        return 0
    }

    func audioDeviceModule(
        _ audioDeviceModule: RTCAudioDeviceModule,
        didDisableEngine engine: AVAudioEngine,
        isPlayoutEnabled: Bool,
        isRecordingEnabled: Bool
    ) -> Int {
        subject.send(.didDisableAudioEngine(engine))
        audioLevelsAdapter.uninstall(on: 0)
        isPlayingSubject.send(isPlayoutEnabled)
        isRecordingSubject.send(isRecordingEnabled)
        return 0
    }

    func audioDeviceModule(
        _ audioDeviceModule: RTCAudioDeviceModule,
        willReleaseEngine engine: AVAudioEngine
    ) -> Int {
        subject.send(.willReleaseAudioEngine(engine))
        audioLevelsAdapter.uninstall(on: 0)
        return 0
    }

    func audioDeviceModule(
        _ audioDeviceModule: RTCAudioDeviceModule,
        engine: AVAudioEngine,
        configureInputFromSource source: AVAudioNode?,
        toDestination destination: AVAudioNode,
        format: AVAudioFormat,
        context: [AnyHashable: Any]
    ) -> Int {
        audioLevelsAdapter.installInputTap(
            on: destination,
            format: format,
            bus: 0,
            bufferSize: 1024
        )
        return 0
    }

    func audioDeviceModule(
        _ audioDeviceModule: RTCAudioDeviceModule,
        engine: AVAudioEngine,
        configureOutputFromSource source: AVAudioNode,
        toDestination destination: AVAudioNode?,
        format: AVAudioFormat,
        context: [AnyHashable: Any]
    ) -> Int {
        0
    }

    func audioDeviceModuleDidUpdateDevices(
        _ audioDeviceModule: RTCAudioDeviceModule
    ) {
        // TODO:
    }

    private enum CodingKeys: String, CodingKey {
        case isPlaying
        case isRecording
        case isMicrophoneMuted
        case audioLevel
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isPlaying, forKey: .isPlaying)
        try container.encode(isRecording, forKey: .isRecording)
        try container.encode(isMicrophoneMuted, forKey: .isMicrophoneMuted)
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

        guard result != 0 else {
            return
        }

        throw ClientError(
            "\(message()) (Error code:\(result))",
            file,
            line
        )
    }
}
