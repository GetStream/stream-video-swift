//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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

final class MockAudioProcessingModule: NSObject, AudioProcessingModule, @unchecked Sendable {
    var config: RTCAudioProcessingConfig = .init()
    static let shared = MockAudioProcessingModule()
    override private init() {}
    private var audioFilter: AudioFilter?
    var activeAudioFilter: AudioFilter? { audioFilter }
    func setAudioFilter(_ filter: AudioFilter?) { audioFilter = filter }
    func apply(_ config: RTCAudioProcessingConfig) {}
}
