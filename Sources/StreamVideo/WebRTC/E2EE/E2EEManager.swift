//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// Plug-in surface for attaching end-to-end encryption to RTP senders and
/// receivers.
///
/// ## Overview
/// The RTC layer only needs two operations: wrap a sender so outgoing
/// encoded frames are encrypted, and wrap a receiver so incoming frames are
/// decrypted. ``EncryptionManager`` is the built-in AES-GCM implementation.
/// ``Call/setE2EEManager(_:)`` accepts any object that conforms, so an
/// integrator can plug in another scheme by attaching their own encoded
/// transform in these two methods.
///
/// ## Usage
/// Attach a manager **before** ``Call/join(create:options:ring:notify:callSettings:policy:joinInterceptor:)``.
/// After peer connections exist the call cannot adopt encryption without
/// leaving the live session half-encrypted, so ``Call/setE2EEManager(_:)``
/// throws in that case.
public protocol E2EEManager: AnyObject, Sendable {
    /// Attaches an encryptor to `sender`.
    ///
    /// `trackType` groups replay windows so a camera and a screen share from
    /// the same user stay independent. `codec` is an exact lowercase pin
    /// (`opus` / `vp8` / `vp9` / `h264`); pass `nil` to read the codec from
    /// the encoded frame.
    ///
    /// - Parameters:
    ///   - sender: The RTP sender created for the local track.
    ///   - codec: Exact lowercase codec pin, or `nil` to inspect the frame.
    ///   - trackType: Replay-window grouping; typically `.audio`, `.video`,
    ///     or `.screenshare`.
    /// - Throws: If the encryptor cannot be attached (missing key, disposed
    ///   manager, or an unsupported codec pin).
    func encrypt(
        _ sender: RTCRtpSender,
        codec: String?,
        trackType: TrackType?
    ) throws

    /// Attaches a decryptor to `receiver`.
    ///
    /// `trackType` groups replay windows so a peer's audio and video stay
    /// independent. `userId` selects the key that the remote participant
    /// used when encrypting.
    ///
    /// - Parameters:
    ///   - receiver: The RTP receiver for the remote track.
    ///   - userId: The key owner; normally the remote participant's user id.
    ///   - trackType: Replay-window grouping; typically `.audio`, `.video`,
    ///     or `.screenshare`.
    /// - Throws: If the decryptor cannot be attached (missing key, disposed
    ///   manager, or an unknown user).
    func decrypt(
        _ receiver: RTCRtpReceiver,
        userId: String,
        trackType: TrackType?
    ) throws
}
