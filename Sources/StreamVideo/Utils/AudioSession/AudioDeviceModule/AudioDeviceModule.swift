//
//  AudioDeviceModule.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 8/10/25.
//

import Foundation
import StreamWebRTC
import Combine
import AVFoundation

final class AudioDeviceModule: NSObject, RTCAudioDeviceModuleDelegate {

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
    var isStereoPlayoutAvailable: Bool = false
    var isStereoPlayoutAvailablePublisher: AnyPublisher<Bool, Never> { _isStereoPlayoutAvailable.publisher }

    @SafePublished
    var isStereoPlayoutEnabled: Bool = false
    var isStereoPlayoutEnabledPublisher: AnyPublisher<Bool, Never> { _isStereoPlayoutEnabled.publisher }

    @SafePublished
    var audioLevel: Float = 0
    var audioLevelPublisher: AnyPublisher<Float, Never> { _audioLevel.publisher }

    private let source: RTCAudioDeviceModule
    private let disposableBag: DisposableBag = .init()

    private let dispatchQueue: DispatchQueue
    private let subject: PassthroughSubject<Event, Never>
    private lazy var audioLevelsAdapter: AudioEngineLevelNodeAdapter = .init { [weak self] in self?._audioLevel.set($0) }
    let publisher: AnyPublisher<Event, Never>

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
            .publisher(for: \.isStereoPlayoutAvailable)
            .sink { [weak self] in self?._isStereoPlayoutAvailable.set($0) }
            .store(in: disposableBag)

        source
            .publisher(for: \.isStereoPlayoutEnabled)
            .sink { [weak self] in self?._isStereoPlayoutEnabled.set($0) }
            .store(in: disposableBag)
    }

    // MARK: - Stereo Playout

    func setStereoPlayout(enabled: Bool) {
        guard enabled != source.isStereoPlayoutEnabled else {
            return
        }
        source.isStereoPlayoutEnabled = enabled
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

        audioLevelsAdapter.install(on: engine)

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
        audioLevelsAdapter.uninstall(on: engine)
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
        audioLevelsAdapter.uninstall(on: engine)
        _isPlaying.set(isPlayoutEnabled)
        _isRecording.set(isRecordingEnabled)
        return 0
    }

    func audioDeviceModule(
        _ audioDeviceModule: RTCAudioDeviceModule,
        willReleaseEngine engine: AVAudioEngine
    ) -> Int {
        subject.send(.willReleaseAudioEngine(engine))
        audioLevelsAdapter.uninstall(on: engine)
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
        0
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
}
