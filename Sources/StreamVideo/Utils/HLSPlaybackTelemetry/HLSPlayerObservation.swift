//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

/// One player change waiting to be recorded.
///
/// The collector's observers send these in the order the player emits them.
/// A serial queue then applies them one at a time.
enum HLSPlayerObservation {
    /// `timeControlStatus` changed. The values are the ones observed.
    case timeControl(
        status: AVPlayer.TimeControlStatus,
        waitingReason: AVPlayer.WaitingReason?
    )

    /// The player reported an error. `code` is the domain and code, capped.
    case failure(code: String)
}
