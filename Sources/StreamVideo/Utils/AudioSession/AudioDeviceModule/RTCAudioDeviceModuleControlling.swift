//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import StreamWebRTC

/// Abstraction over `RTCAudioDeviceModule` so tests can provide fakes while
/// production code keeps using the WebRTC implementation.
protocol RTCAudioDeviceModuleControlling: AnyObject {
    var observer: RTCAudioDeviceModuleDelegate? { get set }
    var isMicrophoneMuted: Bool { get }
    var isStereoPlayoutEnabled: Bool { get }
    var isStereoPlayoutAvailable: Bool { get }
    var isVoiceProcessingBypassed: Bool { get }
    var isVoiceProcessingEnabled: Bool { get }
    var isVoiceProcessingAGCEnabled: Bool { get }
    var manualRestoreVoiceProcessingOnMono: Bool { get set }

    func initAndStartRecording() -> Int
    func setMicrophoneMuted(_ isMuted: Bool) -> Int
    func stopRecording() -> Int
    func setVoiceProcessingEnabled(_ isEnabled: Bool) -> Int
    func setVoiceProcessingBypassed(_ isBypassed: Bool) -> Int
    func setVoiceProcessingAGCEnabled(_ isEnabled: Bool) -> Int
    func setStereoPlayoutEnabled(_ isEnabled: Bool) -> Int

    /// Publisher that emits whenever the microphone mute state changes.
    func microphoneMutedPublisher() -> AnyPublisher<Bool, Never>
    func isStereoPlayoutEnabledPublisher() -> AnyPublisher<Bool, Never>
    func isVoiceProcessingBypassedPublisher() -> AnyPublisher<Bool, Never>
    func isVoiceProcessingEnabledPublisher() -> AnyPublisher<Bool, Never>
    func isVoiceProcessingAGCEnabledPublisher() -> AnyPublisher<Bool, Never>
}

extension RTCAudioDeviceModule: RTCAudioDeviceModuleControlling {
    func microphoneMutedPublisher() -> AnyPublisher<Bool, Never> {
        publisher(for: \.isMicrophoneMuted)
            .eraseToAnyPublisher()
    }

    func isStereoPlayoutEnabledPublisher() -> AnyPublisher<Bool, Never> {
        publisher(for: \.isStereoPlayoutEnabled)
            .eraseToAnyPublisher()
    }

    func isVoiceProcessingBypassedPublisher() -> AnyPublisher<Bool, Never> {
        publisher(for: \.isVoiceProcessingBypassed)
            .eraseToAnyPublisher()
    }

    func isVoiceProcessingEnabledPublisher() -> AnyPublisher<Bool, Never> {
        publisher(for: \.isVoiceProcessingEnabled)
            .eraseToAnyPublisher()
    }

    func isVoiceProcessingAGCEnabledPublisher() -> AnyPublisher<Bool, Never> {
        publisher(for: \.isVoiceProcessingAGCEnabled)
            .eraseToAnyPublisher()
    }
}
