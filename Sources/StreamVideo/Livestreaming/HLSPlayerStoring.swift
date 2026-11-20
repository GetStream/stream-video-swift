//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

/// The player store the HLS views use.
///
/// StreamVideoSwiftUI uses this protocol. The store is not a public type.
package protocol HLSPlayerStoring: AnyObject, Sendable {
    /// The player of the call, if it has one.
    func player(for call: Call) async -> AVPlayer?

    /// Takes a claim on the player of the call.
    ///
    /// The first claim creates the player and starts it. Later claims of the
    /// same call receive the same player. Returns nil when `playbackType` is
    /// not HLS.
    func acquire(
        for call: Call,
        playbackType: PlaybackType
    ) async -> (any HLSPlayerLeasing)?
}
