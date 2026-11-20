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
actor HLSStateAdapter {
    let unifiedSessionId: String

    /// Replaces report delivery in tests.
    ///
    /// Nil posts through ``HLSStatsDelivery``.
    private(set) var statsDelivering: HLSStatsDelivering?

    func setStatsDelivering(_ delivering: HLSStatsDelivering?) {
        statsDelivering = delivering
    }

    /// The API client is not `Sendable`. The call keeps one client, and this
    /// adapter only reads it.
    private let endpoints: UncheckedSendableBox<DefaultAPIEndpoints>

    init(
        unifiedSessionId: String,
        endpoints: UncheckedSendableBox<DefaultAPIEndpoints>
    ) {
        self.unifiedSessionId = unifiedSessionId
        self.endpoints = endpoints
    }

    /// Builds the adapter that reports playback of `player` for `call`.
    ///
    /// Returns nil when `call` has no call session id, when
    /// `unifiedSessionId` is empty, or when delivery cannot be created.
    func reportingAdapter(player: AVPlayer, call: Call) async -> HLSStatsAdapter? {
        let callSessionId = await call.state.session?.id ?? ""
        guard !callSessionId.isEmpty, !unifiedSessionId.isEmpty else {
            return nil
        }
        let delivery = statsDelivering ?? HLSStatsDelivery(endpoints: endpoints.value)
        guard let delivery else { return nil }
        // JoinCallResponse.statsOptions.reportingIntervalMs is stored on
        // CallState as seconds. The generated model has no
        // reporting_hls_interval_ms. Zero means the join response sent 0.
        let reportingIntervalSeconds = await call.state.statsCollectionInterval
        let seconds = reportingIntervalSeconds > 0
            ? TimeInterval(reportingIntervalSeconds)
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
