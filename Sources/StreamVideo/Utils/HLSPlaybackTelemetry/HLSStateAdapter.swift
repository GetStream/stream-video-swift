//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

/// Holds the call values HLS playback reporting needs.
///
/// `unifiedSessionId` is the id ``WebRTCStateAdapter`` created. This adapter
/// keeps the value it was given so a report can send it without reading the
/// WebRTC adapter again.
final class HLSStateAdapter {
    let unifiedSessionId: String

    /// Replaces report delivery in tests.
    ///
    /// Nil posts through ``HLSStatsDelivery``.
    var statsDelivering: HLSStatsDelivering?

    private let endpoints: DefaultAPIEndpoints

    init(unifiedSessionId: String, endpoints: DefaultAPIEndpoints) {
        self.unifiedSessionId = unifiedSessionId
        self.endpoints = endpoints
    }

    /// Builds the adapter that reports playback of `player` for `call`.
    ///
    /// Returns nil when `call` has no call session id, when
    /// `unifiedSessionId` is empty, or when delivery cannot be created.
    @MainActor
    func reportingAdapter(player: AVPlayer, call: Call) -> HLSStatsAdapter? {
        let callSessionId = call.state.session?.id ?? ""
        guard !callSessionId.isEmpty, !unifiedSessionId.isEmpty else {
            return nil
        }
        let delivery = statsDelivering ?? HLSStatsDelivery(endpoints: endpoints)
        guard let delivery else { return nil }
        let seconds = call.state.statsCollectionInterval > 0
            ? TimeInterval(call.state.statsCollectionInterval)
            : 5
        return HLSStatsAdapter(
            player: player,
            callType: call.callType,
            callId: call.callId,
            callSessionId: callSessionId,
            unifiedSessionId: unifiedSessionId,
            interval: seconds,
            delivery: delivery
        )
    }
}
