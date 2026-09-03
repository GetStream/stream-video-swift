//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// Desired music vs last successful Voice Processing apply.
///
/// Desired stays set until apply succeeds so a failed unmute-deferred
/// apply can retry. Stereo preference is a live-graph overlay (bypass
/// only) and is not stored here. Leaving music while stereo is preferred
/// records ``Applied/voiceWhileStereo``: VP stays off, AGC returns.
struct MusicCapturePolicy {

    /// Last successful music-toggle apply to the ADM.
    enum Applied: Equatable {
        /// VP on, AGC on, not bypassed.
        case voice
        /// VP off, AGC off, bypassed.
        case music
        /// Left music while stereo is preferred: VP stays off, AGC on,
        /// bypassed.
        case voiceWhileStereo

        /// `true` only for the music apply, not ``voiceWhileStereo``.
        var isMusic: Bool { self == .music }
    }

    /// VP work that could not run because the mic was muted.
    ///
    /// Mute → music → unmute was silent when we rebuilt VP against mixer
    /// volume 0: AURemoteIO never started. Store the work here and apply
    /// it on unmute.
    enum Pending: Equatable {
        case none
        /// Apply after unmute. `restorePlayout` is sticky: any muted
        /// toggle that asked for a restart wins.
        case applyVoiceProcessing(restorePlayout: Bool)
    }

    /// Knobs for one capture-policy apply (music toggle / unmute).
    ///
    /// Stereo *preference* never uses this: it only bypasses VP.
    /// ``voiceWhileStereo`` is the music-exit path with stereo on.
    struct Configuration: Equatable {
        var voiceProcessingEnabled: Bool
        var agcEnabled: Bool
        var bypassVoiceProcessing: Bool

        /// Mixer mute when VP is bypassed; Voice Processing mute otherwise.
        var muteMode: RTCAudioEngineMuteMode {
            bypassVoiceProcessing ? .inputMixer : .voiceProcessing
        }

        /// VoiceChat: enable VP and AGC, do not bypass.
        static let voice = Configuration(
            voiceProcessingEnabled: true,
            agcEnabled: true,
            bypassVoiceProcessing: false
        )

        /// Music: disable VP (rebuild I/O), AGC off, bypass.
        static let music = Configuration(
            voiceProcessingEnabled: false,
            agcEnabled: false,
            bypassVoiceProcessing: true
        )

        /// Left music with stereo preferred: VP stays off, AGC on.
        static let voiceWhileStereo = Configuration(
            voiceProcessingEnabled: false,
            agcEnabled: true,
            bypassVoiceProcessing: true
        )
    }

    private(set) var desiredMusicEnabled = false
    private(set) var applied: Applied = .voice
    private(set) var pending: Pending = .none

    /// Keep-graph and other music-only engine behavior follow desired
    /// music, including a muted toggle that has not applied yet.
    var isMusicCaptureEnabled: Bool { desiredMusicEnabled }

    /// `true` when unmute (or a retry) still owes a capture apply.
    var hasPendingApply: Bool { pending != .none }

    /// Sticky playout restore from a muted toggle. `false` if none.
    var pendingRestorePlayout: Bool {
        if case .applyVoiceProcessing(let restore) = pending {
            return restore
        }
        return false
    }

    /// Knobs for rolling back to the last successful apply.
    var appliedConfiguration: Configuration {
        switch applied {
        case .voice: return .voice
        case .music: return .music
        case .voiceWhileStereo: return .voiceWhileStereo
        }
    }

    /// Bypass + mixer mute for the live graph (stereo overlay).
    ///
    /// Stereo preference uses this and must not call
    /// `setVoiceProcessingEnabled`. ``voiceWhileStereo`` stays bypassed
    /// after stereo turns off until capture apply re-enables VP, so mute
    /// does not sit on `.voiceProcessing` with VP still disabled.
    func bypassVoiceProcessing(stereoPreferred: Bool) -> Bool {
        desiredMusicEnabled
            || stereoPreferred
            || applied == .voiceWhileStereo
    }

    /// Music-exit left VP off for stereo. Stereo-off must re-enable VP;
    /// never-music stereo still only bypasses.
    func needsVoiceProcessingRestore(
        stereoPreferred: Bool
    ) -> Bool {
        applied == .voiceWhileStereo
            && !desiredMusicEnabled
            && !stereoPreferred
    }

    /// Capture-apply knobs for current desired music + stereo.
    func configuration(stereoPreferred: Bool) -> Configuration {
        if desiredMusicEnabled { return .music }
        if stereoPreferred { return .voiceWhileStereo }
        return .voice
    }

    /// `true` when this request must apply (or defer), not no-op.
    ///
    /// Same desired after a failed apply still returns `true` because
    /// ``applied`` has not caught up. Stereo preference alone does not
    /// count: never-music stereo only bypasses VP.
    func needsCaptureApply(desiredMusic: Bool) -> Bool {
        desiredMusic != desiredMusicEnabled
            || applied.isMusic != desiredMusic
    }

    /// Records desired music. While muted, only pending is stored.
    mutating func setDesiredMusic(
        _ isEnabled: Bool,
        restorePlayout: Bool,
        isMuted: Bool
    ) {
        desiredMusicEnabled = isEnabled
        guard isMuted else { return }
        if (applied == .voice && !isEnabled)
            || (applied == .music && isEnabled) {
            pending = .none
            return
        }
        let pendingRestore: Bool
        if case .applyVoiceProcessing(let existing) = pending {
            pendingRestore = existing || restorePlayout
        } else {
            pendingRestore = restorePlayout
        }
        pending = .applyVoiceProcessing(
            restorePlayout: pendingRestore
        )
    }

    /// Call only after VP/AGC/bypass applied without throwing.
    mutating func markApplied(stereoPreferred: Bool) {
        if desiredMusicEnabled {
            applied = .music
        } else if stereoPreferred {
            applied = .voiceWhileStereo
        } else {
            applied = .voice
        }
        pending = .none
    }
}
