//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Posts one HLS playback report with the same retry policy as client events.
///
/// Delivery calls ``DefaultAPI/reportHLSStats(type:id:report:)``. A failed
/// report is logged and does not fail playback. `4xx` responses are not
/// retried. Other client failures retry with ``RetryPolicy/clientEventReporting``.
final nonisolated class HLSStatsDelivery: HLSStatsDelivering {
    private let api: DefaultAPI
    private let retryPolicy: RetryPolicy

    nonisolated init?(
        endpoints: DefaultAPIEndpoints,
        retryPolicy: RetryPolicy = .clientEventReporting
    ) {
        guard let api = endpoints as? DefaultAPI else { return nil }
        self.api = api
        self.retryPolicy = retryPolicy
    }

    nonisolated func deliver(
        callType: String,
        callId: String,
        report: HLSStatsReport
    ) async throws {
        var retries = 0
        while true {
            do {
                _ = try await api.reportHLSStats(
                    type: callType,
                    id: callId,
                    report: report
                )
                return
            } catch {
                guard retries < retryPolicy.maxRetries, error.hasClientErrors else {
                    log.debug(
                        "Failed to report HLS playback \(report.type): \(error)",
                        subsystems: .webRTC
                    )
                    return
                }
                let delay = retryPolicy.delay(retries)
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                retries += 1
            }
        }
    }
}
