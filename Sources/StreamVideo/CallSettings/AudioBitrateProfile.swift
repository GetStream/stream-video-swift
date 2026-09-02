//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Audio capture/publish quality profile.
///
/// ``musicHighQuality`` is the in-call music path: software NS/HPF off, the
/// audio session leaves VoiceChat, Voice Processing is disabled (not only
/// bypassed), and a higher Opus bitrate is used. Voice profiles keep
/// platform processing on. ``voiceHighQuality`` is bitrate-only; it is
/// not music.
public enum AudioBitrateProfile: Sendable, Hashable, CaseIterable {
    /// Default voice capture at 64 kbps.
    case voiceStandard
    /// Voice capture at 128 kbps with processing still enabled.
    case voiceHighQuality
    /// Music capture at 128 kbps with speech processing disabled.
    case musicHighQuality

    /// Fallback bitrate when the SFU does not advertise a profile mapping.
    public var defaultBitrate: Int {
        switch self {
        case .voiceStandard:
            return 64_000
        case .voiceHighQuality, .musicHighQuality:
            return 128_000
        }
    }

    /// `true` when this profile should disable speech-oriented processing
    /// (session, VP, NS/HPF, live filters). Bitrate-only profiles return
    /// `false`.
    var isMusic: Bool { self == .musicHighQuality }
}

extension AudioBitrateProfile {

    init?(_ sfuProfile: Stream_Video_Sfu_Models_AudioBitrateProfile) {
        switch sfuProfile {
        case .voiceStandardUnspecified:
            self = .voiceStandard
        case .voiceHighQuality:
            self = .voiceHighQuality
        case .musicHighQuality:
            self = .musicHighQuality
        case .UNRECOGNIZED:
            return nil
        }
    }

    var sfuProfile: Stream_Video_Sfu_Models_AudioBitrateProfile {
        switch self {
        case .voiceStandard:
            return .voiceStandardUnspecified
        case .voiceHighQuality:
            return .voiceHighQuality
        case .musicHighQuality:
            return .musicHighQuality
        }
    }
}
