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
    var isVoiceProcessingBypassed: Bool { get }
    var isVoiceProcessingEnabled: Bool { get }
    var isVoiceProcessingAGCEnabled: Bool { get }
    var isManualRestoreVoiceProcessingOnMono: Bool { get }
    var prefersStereoPlayout: Bool { get set }

    func terminate() -> Int
    func initAndStartPlayout() -> Int
    func startPlayout() -> Int
    func stopPlayout() -> Int
    func initAndStartRecording() -> Int
    func setMicrophoneMuted(_ isMuted: Bool) -> Int
    func stopRecording() -> Int
    func setManualRestoreVoiceProcessingOnMono(_ isEnabled: Bool)
    func refreshStereoPlayoutState()

    /// Publisher that emits whenever the microphone mute state changes.
    func microphoneMutedPublisher() -> AnyPublisher<Bool, Never>
    func isVoiceProcessingBypassedPublisher() -> AnyPublisher<Bool, Never>
    func isVoiceProcessingEnabledPublisher() -> AnyPublisher<Bool, Never>
    func isVoiceProcessingAGCEnabledPublisher() -> AnyPublisher<Bool, Never>
}

extension RTCAudioDeviceModule: RTCAudioDeviceModuleControlling {
    func initAndStartPlayout() -> Int {
        let result = initPlayout()
        if result == 0 {
            return startPlayout()
        } else {
            return result
        }
    }
    
    func microphoneMutedPublisher() -> AnyPublisher<Bool, Never> {
        publisher(for: \.isMicrophoneMuted)
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
