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

    func initAndStartRecording() -> Int
    func setMicrophoneMuted(_ isMuted: Bool) -> Int
    func stopRecording() -> Int

    /// Publisher that emits whenever the microphone mute state changes.
    func microphoneMutedPublisher() -> AnyPublisher<Bool, Never>
}

extension RTCAudioDeviceModule: RTCAudioDeviceModuleControlling {
    func microphoneMutedPublisher() -> AnyPublisher<Bool, Never> {
        publisher(for: \.isMicrophoneMuted)
            .eraseToAnyPublisher()
    }
}
