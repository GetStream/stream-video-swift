//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// Shared box so local adapters can read the call's E2EE manager at
/// transceiver-attach time without threading it through every factory.
///
/// ## Overview
/// Publisher peer connections create audio, video, and screenshare adapters
/// from a single context. ``RTCPeerConnectionCoordinator/attachE2EE(_:)``
/// writes the manager after construction and before `setUp`, so
/// `addTransceiver` can encrypt without exploding every initializer
/// signature.
///
/// Access is serialized on `UnfairQueue` because local adapters publish
/// from WebRTC callbacks while the coordinator attaches the manager from
/// the state-adapter actor.
final class E2EEAttachmentContext: @unchecked Sendable {
    private let queue = UnfairQueue()
    private var _manager: E2EEManager?

    /// The call's E2EE manager, or `nil` when encryption is off.
    var manager: E2EEManager? {
        get { queue.sync { _manager } }
        set { queue.sync { _manager = newValue } }
    }

    /// Attaches an encryptor to `sender` when a manager is set.
    ///
    /// Matches JS `Publisher.addTransceiver`: attach failure is fail-closed.
    /// The sender track is cleared and the error is rethrown so the
    /// transceiver is not stored or announced.
    ///
    /// - Parameters:
    ///   - sender: The RTP sender on the newly added transceiver.
    ///   - codec: Exact lowercase pin (`opus` / `vp8` / `vp9` / `h264`),
    ///     or `nil` to read the codec from the frame.
    ///   - trackType: Replay-window grouping for this track.
    func encryptIfNeeded(
        sender: RTCRtpSender,
        codec: String?,
        trackType: TrackType
    ) throws {
        guard let manager else { return }
        do {
            try manager.encrypt(sender, codec: codec, trackType: trackType)
            log.debug(
                "E2EE encryptor attached to sender codec:\(codec ?? "nil") trackType:\(trackType).",
                subsystems: .webRTC
            )
        } catch {
            sender.track = nil
            log.error(error, subsystems: .webRTC)
            throw error
        }
    }
}
