//
//  AudioDeviceModule.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 8/10/25.
//

import AVFoundation
import Combine
import Foundation
import StreamWebRTC

final class AudioDeviceModule: NSObject, RTCAudioDeviceModuleDelegate, Encodable, @unchecked Sendable {

    enum Event {
        case speechActivityStarted
        case speechActivityEnded
        case didCreateAudioEngine(AVAudioEngine)
        case willEnableAudioEngine(AVAudioEngine)
        case willStartAudioEngine(AVAudioEngine)
        case didStopAudioEngine(AVAudioEngine)
        case didDisableAudioEngine(AVAudioEngine)
        case willReleaseAudioEngine(AVAudioEngine)
    }

    @SafePublished
    var isPlaying: Bool = false
    var isPlayingPublisher: AnyPublisher<Bool, Never> { _isPlaying.publisher }

    @SafePublished
    var isRecording: Bool = false
    var isRecordingPublisher: AnyPublisher<Bool, Never> { _isRecording.publisher }

    @SafePublished
    var isMicrophoneMuted: Bool = false
    var isMicrophoneMutedPublisher: AnyPublisher<Bool, Never> { _isMicrophoneMuted.publisher }

    @SafePublished
    var audioLevel: Float = 0
    var audioLevelPublisher: AnyPublisher<Float, Never> { _audioLevel.publisher }

    private let source: RTCAudioDeviceModule
    private let disposableBag: DisposableBag = .init()

    private let dispatchQueue: DispatchQueue
    private let subject: PassthroughSubject<Event, Never>
    private lazy var audioLevelsAdapter: AudioEngineLevelNodeAdapter = .init { [weak self] in self?._audioLevel.set($0) }
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

    init(_ source: RTCAudioDeviceModule) {
        self.source = source
        let dispatchQueue = DispatchQueue(label: "io.getstream.audiodevicemodule", qos: .userInteractive)
        let subject = PassthroughSubject<Event, Never>()
        self.subject = subject
        self.dispatchQueue = dispatchQueue
        self.publisher = subject
            .receive(on: dispatchQueue)
            .eraseToAnyPublisher()
        super.init()

        source.observer = self

        source
            .publisher(for: \.isMicrophoneMuted)
            .receive(on: dispatchQueue)
            .sink { [weak self] in self?._isMicrophoneMuted.set($0) }
            .store(in: disposableBag)

    }

    // MARK: - Recording

    func setRecording(_ isEnabled: Bool) {
        guard isEnabled != isRecording else {
            return
        }

        if isEnabled {
            let isMicrophoneMuted = source.isMicrophoneMuted

            let result = source.initAndStartRecording()
            if result == 0 {
                // After restarting the ADM it always returns with microphoneMute:false.
                // Here we reinstate the muted condition after restarting ADM.
                if isMicrophoneMuted {
                    let result = source.setMicrophoneMuted(isMicrophoneMuted)
                }
            } else {
                log.error("setRecording:\(isEnabled) failed with result:\(result).", subsystems: .audioSession)
            }
        } else {
            source.stopRecording()
        }
    }

    func setMuted(_ isMuted: Bool) {
        guard isMuted != isMicrophoneMuted else {
            return
        }

        let result = source.setMicrophoneMuted(isMuted)
        if result == 0{
            self._isMicrophoneMuted.set(isMuted)
        } else {
            log.error("setMicrophoneMuted:\(isMuted) failed with result:\(result).", subsystems: .audioSession)
        }
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
        _isPlaying.set(isPlayoutEnabled)
        _isRecording.set(isRecordingEnabled)
        return 0
    }

    func audioDeviceModule(
        _ audioDeviceModule: RTCAudioDeviceModule,
        willStartEngine engine: AVAudioEngine,
        isPlayoutEnabled: Bool,
        isRecordingEnabled: Bool
    ) -> Int {
        subject.send(.willStartAudioEngine(engine))
        _isPlaying.set(isPlayoutEnabled)
        _isRecording.set(isRecordingEnabled)
        return 0
    }

    func audioDeviceModule(
        _ audioDeviceModule: RTCAudioDeviceModule,
        didStopEngine engine: AVAudioEngine,
        isPlayoutEnabled: Bool,
        isRecordingEnabled: Bool
    ) -> Int {
        subject.send(.didStopAudioEngine(engine))
        audioLevelsAdapter.uninstall()
        _isPlaying.set(isPlayoutEnabled)
        _isRecording.set(isRecordingEnabled)
        return 0
    }

    func audioDeviceModule(
        _ audioDeviceModule: RTCAudioDeviceModule,
        didDisableEngine engine: AVAudioEngine,
        isPlayoutEnabled: Bool,
        isRecordingEnabled: Bool
    ) -> Int {
        subject.send(.didDisableAudioEngine(engine))
        audioLevelsAdapter.uninstall()
        _isPlaying.set(isPlayoutEnabled)
        _isRecording.set(isRecordingEnabled)
        return 0
    }

    func audioDeviceModule(
        _ audioDeviceModule: RTCAudioDeviceModule,
        willReleaseEngine engine: AVAudioEngine
    ) -> Int {
        subject.send(.willReleaseAudioEngine(engine))
        audioLevelsAdapter.uninstall()
        return 0
    }

    func audioDeviceModule(
        _ audioDeviceModule: RTCAudioDeviceModule,
        engine: AVAudioEngine,
        configureInputFromSource source: AVAudioNode?,
        toDestination destination: AVAudioNode,
        format: AVAudioFormat,
        context: [AnyHashable : Any]
    ) -> Int {
        audioLevelsAdapter.installInputTap(on: destination, format: format)
        return 0
    }

    func audioDeviceModule(
        _ audioDeviceModule: RTCAudioDeviceModule,
        engine: AVAudioEngine,
        configureOutputFromSource source: AVAudioNode,
        toDestination destination: AVAudioNode?,
        format: AVAudioFormat,
        context: [AnyHashable : Any]
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
}
