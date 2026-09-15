//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

extension RTCMediaConstraints {
    
    /// Optional constraints shared by default and ICE restart configurations.
    private static let commonOptionalConstraints: [String: String] = [
        "DtlsSrtpKeyAgreement": kRTCMediaConstraintsValueTrue,
        /// Added support for Google's media constraints to improve transmitted audio
        /// https://github.com/GetStream/react-native-webrtc/pull/20/commits/6476119456005dc35ba00e9bf4d4c4124c6066e8
        "googAutoGainControl": kRTCMediaConstraintsValueTrue,
        "googNoiseSuppression": kRTCMediaConstraintsValueTrue,
        "googEchoCancellation": kRTCMediaConstraintsValueTrue,
        "googHighpassFilter": kRTCMediaConstraintsValueTrue,
        "googTypingNoiseDetection": kRTCMediaConstraintsValueTrue,
        "googAudioMirroring": kRTCMediaConstraintsValueFalse
    ]

    nonisolated(unsafe) static let defaultConstraints = RTCMediaConstraints(
        mandatoryConstraints: nil,
        optionalConstraints: commonOptionalConstraints
    )
    
    nonisolated(unsafe) static let iceRestartConstraints = RTCMediaConstraints(
        mandatoryConstraints: [kRTCMediaConstraintsIceRestart: kRTCMediaConstraintsValueTrue],
        optionalConstraints: commonOptionalConstraints
    )

    /// Music capture flags baked into `RTCAudioSource` at create time.
    ///
    /// Software NS, HPF, AEC, AGC, and typing-noise detection are off.
    /// `LocalAudioSource` copies these goog* keys once and has no
    /// setter; unmute `SetAudioSend` reapplies them via `SetOptions`.
    /// Derived from the voice defaults so DTLS and mirroring cannot
    /// drift independently.
    private static let musicOptionalConstraints: [String: String] = {
        var constraints = commonOptionalConstraints
        constraints["googAutoGainControl"] = kRTCMediaConstraintsValueFalse
        constraints["googNoiseSuppression"] = kRTCMediaConstraintsValueFalse
        constraints["googEchoCancellation"] = kRTCMediaConstraintsValueFalse
        constraints["googHighpassFilter"] = kRTCMediaConstraintsValueFalse
        constraints["googTypingNoiseDetection"] = kRTCMediaConstraintsValueFalse
        return constraints
    }()

    /// Constraints used when creating an `RTCAudioSource` for music.
    ///
    /// Passing these into `PeerConnectionFactory.makeAudioSource` is
    /// what keeps unmute from restoring software processing while
    /// Apple Voice Processing is still disabled.
    private nonisolated(unsafe) static let musicCaptureConstraints = RTCMediaConstraints(
        mandatoryConstraints: nil,
        optionalConstraints: musicOptionalConstraints
    )

    /// Capture constraints for a local `RTCAudioSource`.
    ///
    /// Voice keeps the default goog* processing flags (NS/HPF/AEC/AGC
    /// on). Music turns those flags off. The source is immutable after
    /// create, so switching profiles requires a new source and track
    /// rather than mutating this object.
    ///
    /// - Parameter profile: The active ``AudioBitrateProfile``.
    /// - Returns: Music constraints when `profile.isMusic`, otherwise
    ///   ``defaultConstraints``.
    static func audioCaptureConstraints(
        for profile: AudioBitrateProfile
    ) -> RTCMediaConstraints {
        profile.isMusic ? musicCaptureConstraints : defaultConstraints
    }
}
