//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Delivers already-built client-event payloads to the backend.
///
/// This helper is deliberately separate from ``ClientEventReporter`` actor
/// state so in-flight delivery can outlive call/reporter deallocation. That is
/// important when the user leaves while joining: the reporter schedules the
/// final `completed/failure` event and the call object may be released
/// immediately after.
final class ClientEventDelivery: @unchecked Sendable {
    private let api: DefaultAPIEndpoints
    private let retryPolicy: RetryPolicy

    /// Creates a delivery helper.
    ///
    /// - Parameters:
    ///   - api: API client used to send `ReportClientEventRequest` payloads.
    ///   - retryPolicy: In-memory retry policy for transient delivery failures.
    init(
        api: DefaultAPIEndpoints,
        retryPolicy: RetryPolicy
    ) {
        self.api = api
        self.retryPolicy = retryPolicy
    }

    /// Sends one client event with best-effort retry behavior.
    ///
    /// Transient failures (`5xx`, network error, timeout) are retried according
    /// to ``retryPolicy``. Validation failures (`4xx`) and exhausted retries are
    /// swallowed because event reporting must never fail the active call flow.
    func send(_ event: ClientEvent) async {
        let request = ReportClientEventRequest(events: [event])
        var retries = 0
        while true {
            do {
                _ = try await api.reportClientCallEvent(reportClientEventRequest: request)
                log.debug(
                    "ClientEvent retries:\(retries) request:\(request) reported successfully.",
                    subsystems: .webRTC
                )
                return
            } catch {
                // `hasClientErrors` is `false` for `4xx` validation errors (do
                // not retry) and `true` for `5xx`, network, and timeout errors.
                guard retries < retryPolicy.maxRetries, error.hasClientErrors else {
                    log.debug(
                        "Failed to report client event stage:\(event.stage ?? "-") type:\(event.eventType ?? "-"): \(error)",
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
