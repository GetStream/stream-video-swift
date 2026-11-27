//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Posts HLS playback reports to the coordinator, one at a time and in order.
///
/// Only `started` and `ended` retry, because the next interval replaces a
/// failed `stats` report. A `403` means the stats token is no longer valid, so
/// nothing more is sent.
///
/// Events wait in a buffer until a report that carries them succeeds. A
/// report takes the oldest 100, and the buffer keeps the newest 1,000.
final class HLSStatsReporter: @unchecked Sendable {
    private let api: DefaultAPIEndpoints
    private let callType: String
    private let callId: String
    private let callSessionId: String
    private let unifiedSessionId: String
    private let statsToken: String
    private let userSessionId = UUID().uuidString.lowercased()
    private let currentDate: @Sendable () -> Date
    private let retryPolicy: RetryPolicy
    private let sdk: String
    private let sdkVersion: String
    private let sendQueue = OperationQueue(maxConcurrentOperationCount: 1)
    private let maxEventsPerReport = 100
    private let maxBufferedEvents = 1000
    private let queue = UnfairQueue()
    // `queue` guards the properties below and the order of `sendQueue`.
    private var bufferedEvents: [HLSPlayerEvent] = []
    private var didEnd = false
    private var pendingReports = 0
    private var tokenRejected = false

    /// Whether a report is waiting to be sent or being sent.
    var isBusy: Bool { queue.sync { pendingReports > 0 } }

    /// Whether the backend refused the stats token. Nothing is sent after.
    var isRejected: Bool { queue.sync { tokenRejected } }

    init(
        api: DefaultAPIEndpoints,
        callType: String,
        callId: String,
        callSessionId: String,
        unifiedSessionId: String,
        statsToken: String,
        retryPolicy: RetryPolicy = .hlsStatsReporting,
        currentDate: @escaping @Sendable () -> Date = { Date() },
        sdk: String = SystemEnvironment.sdkName,
        sdkVersion: String = SystemEnvironment.version
    ) {
        self.api = api
        self.callType = callType
        self.callId = callId
        self.callSessionId = callSessionId
        self.unifiedSessionId = unifiedSessionId
        self.statsToken = statsToken
        self.retryPolicy = retryPolicy
        self.currentDate = currentDate
        // The backend allows 50 characters for `sdk` and `sdk_version`.
        self.sdk = String(sdk.prefix(50))
        self.sdkVersion = String(sdkVersion.prefix(50))
    }

    // MARK: - Reporting

    /// Sends the `started` report. `user_session_id` is chosen at creation
    /// and reused.
    func reportPlaybackStarted() {
        enqueue(type: .started, retry: true)
    }

    /// Sends a `stats` report with the latest snapshot and the oldest 100
    /// buffered events. A call after `ended` only buffers the events.
    func reportPlaybackStats(stats: HLSPlaybackStats, events: [HLSPlayerEvent]) {
        enqueue(type: .stats, stats: stats, events: events, retry: false)
    }

    /// Sends the `ended` report with the final snapshot and the buffered
    /// events. It retries like `started`.
    ///
    /// `end_reason` is `error` when `errorCode` is non-empty, and `left`
    /// otherwise. The code is cut to 128 characters.
    func reportPlaybackEnded(
        stats: HLSPlaybackStats,
        events: [HLSPlayerEvent],
        errorCode: String?
    ) {
        let code = errorCode.map { String($0.prefix(128)) }.flatMap { $0.isEmpty ? nil : $0 }
        enqueue(
            type: .ended,
            stats: stats,
            events: events,
            endReason: code == nil ? .left : .error,
            errorCode: code,
            retry: true
        )
    }

    // MARK: - Private Helpers

    private func enqueue(
        type: ReportHLSStatsRequest.ReportHLSStatsRequestType,
        stats: HLSPlaybackStats? = nil,
        events: [HLSPlayerEvent] = [],
        endReason: ReportHLSStatsRequest.ReportHLSStatsRequestEndReason? = nil,
        errorCode: String? = nil,
        retry: Bool
    ) {
        let timestamp = Int(currentDate().timeIntervalSince1970 * 1000)
        queue.sync {
            buffer(events)
            guard !didEnd else { return }
            didEnd = type == .ended
            pendingReports += 1
            sendQueue.addTaskOperation { [self] in
                await send(
                    type: type,
                    stats: stats,
                    endReason: endReason,
                    errorCode: errorCode,
                    timestamp: timestamp,
                    retry: retry
                )
                queue.sync { pendingReports -= 1 }
            }
        }
    }

    /// Appends events and drops the oldest ones beyond the buffer size.
    /// Call inside `queue`.
    private func buffer(_ events: [HLSPlayerEvent]) {
        bufferedEvents.append(contentsOf: events)
        bufferedEvents.removeFirst(max(0, bufferedEvents.count - maxBufferedEvents))
    }

    private func nextEvents() -> [HLSPlayerEvent] {
        queue.sync { Array(bufferedEvents.prefix(maxEventsPerReport)) }
    }

    // ponytail: an overflow while a report is in flight shifts the buffer, so
    // the ack can drop newer events. Only possible at the 1,000 cap, where
    // events are being dropped anyway.
    private func acknowledgeEvents(_ sent: Int) {
        queue.sync {
            bufferedEvents.removeFirst(min(sent, bufferedEvents.count))
        }
    }

    private func send(
        type: ReportHLSStatsRequest.ReportHLSStatsRequestType,
        stats: HLSPlaybackStats?,
        endReason: ReportHLSStatsRequest.ReportHLSStatsRequestEndReason?,
        errorCode: String?,
        timestamp: Int,
        retry: Bool
    ) async {
        guard !isRejected else { return }
        // `started` carries no events, so a final `ended` right after it gets
        // the pending ones.
        let events = type == .started ? [] : nextEvents()
        let report = ReportHLSStatsRequest(
            callSessionId: callSessionId,
            endReason: endReason,
            errorCode: errorCode,
            events: events.isEmpty ? nil : events,
            os: String(SystemEnvironment.clientDetails.os.name.prefix(64)),
            osVersion: String(SystemEnvironment.clientDetails.os.version.prefix(64)),
            sdk: sdk,
            sdkVersion: sdkVersion,
            stats: stats,
            statsToken: statsToken,
            timestamp: timestamp,
            type: type,
            unifiedSessionId: unifiedSessionId,
            userSessionId: userSessionId
        )
        do {
            _ = try await executeTask(
                retryPolicy: retry ? retryPolicy : .init(maxRetries: 0, delay: { _ in 0 }),
                task: {
                    try await api.reportHLSStats(
                        type: callType,
                        id: callId,
                        reportHLSStatsRequest: report
                    )
                },
                // Rate limits and server errors can pass. Other `4xx` cannot.
                shouldRetryError: {
                    $0.hasClientErrors || ($0 as? APIError)?.statusCode == 429
                }
            )
            acknowledgeEvents(events.count)
        } catch {
            log.debug(
                "Failed to report HLS playback \(type): \(error)",
                subsystems: .webRTC
            )
            switch (error as? APIError)?.statusCode {
            case 403:
                // The stats token is invalid, expired, or for another
                // session or user.
                queue.sync { tokenRejected = true }
            case let code? where code != 429 && ClosedRange.clientErrorCodes ~= code:
                // The backend refused the report. Sending it again cannot
                // succeed.
                acknowledgeEvents(events.count)
            default:
                break
            }
        }
    }
}

extension RetryPolicy {

    /// Three retries, after 1, 2, and 4 seconds.
    static let hlsStatsReporting = RetryPolicy(
        maxRetries: 3,
        delay: { 1 * pow(2, Double($0)) }
    )
}
