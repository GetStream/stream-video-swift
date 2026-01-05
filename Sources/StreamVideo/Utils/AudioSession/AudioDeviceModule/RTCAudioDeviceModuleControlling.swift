//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import StreamWebRTC

/// Abstraction over `RTCAudioDeviceModule` so tests can provide fakes while
/// production code continues to rely on the WebRTC-backed implementation.
protocol RTCAudioDeviceModuleControlling: AnyObject {
    var observer: RTCAudioDeviceModuleDelegate? { get set }
    var isPlaying: Bool { get }
    var isRecording: Bool { get }
    var isPlayoutInitialized: Bool { get }
    var isRecordingInitialized: Bool { get }
    var isMicrophoneMuted: Bool { get }
    var isStereoPlayoutEnabled: Bool { get }
    var isVoiceProcessingBypassed: Bool { get set }
    var isVoiceProcessingEnabled: Bool { get }
    var isVoiceProcessingAGCEnabled: Bool { get }
    var prefersStereoPlayout: Bool { get set }

    func reset() -> Int
    func initAndStartPlayout() -> Int
    func startPlayout() -> Int
    func stopPlayout() -> Int
    func initAndStartRecording() -> Int
    func setMicrophoneMuted(_ isMuted: Bool) -> Int
    func startRecording() -> Int
    func stopRecording() -> Int
    func refreshStereoPlayoutState()
    func setMuteMode(_ mode: RTCAudioEngineMuteMode) -> Int
    func setRecordingAlwaysPreparedMode(_ alwaysPreparedRecording: Bool) -> Int
}

extension RTCAudioDeviceModule: RTCAudioDeviceModuleControlling {
    /// Convenience wrapper that mirrors the old `initPlayout` and
    /// `startPlayout` sequence so the caller can request playout in one call.
    func initAndStartPlayout() -> Int {
        let result = initPlayout()
        if result == 0 {
            return startPlayout()
        } else {
            return result
        }
    }
}
