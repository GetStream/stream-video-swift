//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

/// Owns HLS playback reporting for one call.
///
/// ``WebRTCStateAdapter`` owns the unified session id. The call controller
/// passes that id in when it creates this coordinator.
final class HLSCoordinator {
    let stateAdapter: HLSStateAdapter

    init(unifiedSessionId: String, endpoints: DefaultAPIEndpoints) {
        stateAdapter = HLSStateAdapter(
            unifiedSessionId: unifiedSessionId,
            endpoints: UncheckedSendableBox(endpoints)
        )
    }

    /// Builds the adapter that reports playback of `player` for `call`.
    ///
    /// Returns nil when the call has no call session id, or when the
    /// coordinator cannot create a delivery client.
    func reportingAdapter(player: AVPlayer, call: Call) async -> HLSStatsAdapter? {
        await stateAdapter.reportingAdapter(player: player, call: call)
    }
}
