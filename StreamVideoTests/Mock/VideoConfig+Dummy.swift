//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamWebRTC

extension VideoConfig {
    static func dummy(
        audioProcessingModule: AudioProcessingModule = MockAudioProcessingModule.shared
    ) -> VideoConfig {
        .init(audioProcessingModule: audioProcessingModule)
    }
}

final class MockAudioProcessingModule: NSObject, AudioProcessingModule {
    static let shared = MockAudioProcessingModule()

    var activeAudioFilter: AudioFilter? { nil }
    func setAudioFilter(_ filter: AudioFilter?) {}
    func apply(_ config: RTCAudioProcessingConfig) {}
}
