//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Builds HLS playback reports and hands them to ``HLSStatsDelivering``.
///
/// `user_session_id` stays the same from `started` through `ended`.
/// The reporter is not isolated to the main actor. It only builds a report
/// and asks delivery to post it.
final class HLSStatsReporter {
    private let callType: String
    private let callId: String
    private let callSessionId: String
    private let unifiedSessionId: String
    private let userSessionId = UUID().uuidString.lowercased()
    private let delivery: HLSStatsDelivering
    private let now: () -> Date
    private let sdk: String
    private let sdkVersion: String
    private let osName: String
    private let osVersion: String
    private let reservedEventTypes: Set<String> = ["started", "stats", "ended"]

    init(
        callType: String,
        callId: String,
        callSessionId: String,
        unifiedSessionId: String,
        delivery: HLSStatsDelivering,
        now: @escaping () -> Date = { Date() },
        sdk: String = SystemEnvironment.sdkName,
        sdkVersion: String = SystemEnvironment.version,
        osName: String = SystemEnvironment.clientDetails.os.name,
        osVersion: String = SystemEnvironment.clientDetails.os.version
    ) {
        self.callType = callType
        self.callId = callId
        self.callSessionId = callSessionId
        self.unifiedSessionId = unifiedSessionId
        self.delivery = delivery
        self.now = now
        self.sdk = String(sdk.prefix(64))
        self.sdkVersion = String(sdkVersion.prefix(64))
        self.osName = String(osName.prefix(64))
        self.osVersion = String(osVersion.prefix(64))
    }

    /// Sends the `started` report. `user_session_id` is chosen here and reused.
    func reportPlaybackStarted() async {
        await send(type: "started", stats: nil, events: [], endReason: nil, errorCode: nil)
    }

    /// Sends a `stats` report with the latest snapshot and the events since
    /// the previous report. Event types `started`, `stats`, and `ended` are
    /// dropped. At most 100 events are sent.
    func reportPlaybackStats(stats: HLSPlaybackStats, events: [HLSStatsEvent]) async {
        await send(
            type: "stats",
            stats: stats,
            events: events,
            endReason: nil,
            errorCode: nil
        )
    }

    /// Sends the `ended` report.
    ///
    /// `end_reason` is `error` when `errorCode` is non-empty, and `left`
    /// otherwise. The code is cut to 128 characters.
    func reportPlaybackEnded(errorCode: String?) async {
        let code = errorCode.map { String($0.prefix(128)) }.flatMap { $0.isEmpty ? nil : $0 }
        await send(
            type: "ended",
            stats: nil,
            events: [],
            endReason: code == nil ? "left" : "error",
            errorCode: code
        )
    }

    private func send(
        type: String,
        stats: HLSPlaybackStats?,
        events: [HLSStatsEvent],
        endReason: String?,
        errorCode: String?
    ) async {
        let kept = events
            .filter { !reservedEventTypes.contains($0.type) }
            .suffix(100)
        let report = HLSStatsReport(
            callSessionId: callSessionId,
            userSessionId: userSessionId,
            unifiedSessionId: unifiedSessionId,
            type: type,
            timestamp: Int64(now().timeIntervalSince1970 * 1000),
            sdk: sdk,
            sdkVersion: sdkVersion,
            os: osName,
            osVersion: osVersion,
            endReason: endReason,
            errorCode: errorCode,
            stats: stats,
            events: Array(kept)
        )
        try? await delivery.deliver(callType: callType, callId: callId, report: report)
    }
}
