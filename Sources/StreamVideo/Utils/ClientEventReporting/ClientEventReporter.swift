//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Default ``ClientEventReporting`` implementation that builds ``ClientEvent``
/// payloads and delivers them to the coordinator
/// `POST /api/v2/video/call_client_event` endpoint.
///
/// Delivery is best-effort and fire-and-forget:
/// - Each event is sent in its own detached task so the join flow is never
///   blocked on network latency.
/// - Transient failures (`5xx`, network error, timeout) are retried in memory
///   with exponential backoff; validation failures (`4xx`) are not retried.
/// - Nothing is persisted across sessions. A lost completion simply surfaces as
///   a failure server-side, which matches the backend's "absent completion is a
///   failure" model.
actor ClientEventReporter: ClientEventReporting {

    /// The immutable identity shared by every event of a call.
    ///
    /// The generated ``ClientEvent`` carries `type` (call type) and `id` (call
    /// id) but no `call_cid`, so the backend derives the cid from those.
    struct Context: Sendable {
        var userId: String
        var callType: String
        var callId: String
        var sdkVersion: String
        var userAgent: String

        init(
            userId: String,
            callType: String,
            callId: String,
            sdkVersion: String = SystemEnvironment.version,
            userAgent: String = SystemEnvironment.xStreamClientHeader
        ) {
            self.userId = userId
            self.callType = callType
            self.callId = callId
            self.sdkVersion = sdkVersion
            self.userAgent = userAgent
        }
    }

    /// The coordinator client used to deliver events. Declared
    /// `nonisolated(unsafe)` because `DefaultAPIEndpoints` is not `Sendable`
    /// while the concrete client is `@unchecked Sendable` and safe for
    /// concurrent use.
    private nonisolated(unsafe) let api: DefaultAPIEndpoints
    private let context: Context
    private let retryPolicy: RetryPolicy
    private let currentDate: @Sendable () -> Date
    private let disposableBag = DisposableBag()

    /// The id shared across all events of the active join attempt. Regenerated
    /// by ``reportJoinInitiated()`` on every new attempt.
    private(set) var joinAttemptId: String = UUID().uuidString

    /// Stages that were begun but not yet completed, keyed by `stageId`. Used by
    /// ``abortPendingStages(failure:)`` to fail in-progress stages on leave.
    private var activeAttempts: [String: ClientEventStageAttempt] = [:]

    /// Creates a reporter.
    ///
    /// - Parameters:
    ///   - api: The coordinator API used to deliver events.
    ///   - context: The call identity shared by every event.
    ///   - retryPolicy: The in-memory retry policy used when delivery fails.
    ///   - currentDate: Clock used for timestamps and elapsed-time computation.
    init(
        api: DefaultAPIEndpoints,
        context: Context,
        retryPolicy: RetryPolicy = .clientEventReporting,
        currentDate: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.api = api
        self.context = context
        self.retryPolicy = retryPolicy
        self.currentDate = currentDate
    }

    // MARK: - ClientEventReporting

    func reportJoinInitiated() async {
        // A new attempt supersedes the previous one. Drop any stage attempts
        // that never completed so they are not later resolved against the new
        // attempt id; the backend treats their missing completion as a failure.
        activeAttempts.removeAll()
        joinAttemptId = UUID().uuidString
        let event = makeEvent(
            stage: .joinInitiated,
            eventType: .initiated,
            stageId: nil,
            peerConnection: nil
        )
        deliver(event)
    }

    @discardableResult
    func beginStage(
        _ stage: ClientEventStage,
        peerConnection: ClientEventPeerConnection?,
        details: ClientEventStageDetails
    ) async -> ClientEventStageAttempt {
        let attempt = ClientEventStageAttempt(
            stage: stage,
            stageId: UUID().uuidString,
            peerConnection: peerConnection,
            joinAttemptId: joinAttemptId,
            startedAt: currentDate(),
            details: details
        )

        activeAttempts[attempt.stageId] = attempt

        let event = makeEvent(
            stage: stage,
            eventType: .initiated,
            stageId: attempt.stageId,
            peerConnection: peerConnection,
            joinAttemptId: attempt.joinAttemptId,
            details: details
        )
        deliver(event)

        return attempt
    }

    func completeStage(
        _ attempt: ClientEventStageAttempt,
        outcome: ClientEventOutcome,
        retryCount: Int,
        details: ClientEventStageDetails,
        failure: ClientEventFailure?
    ) async {
        guard activeAttempts.removeValue(forKey: attempt.stageId) != nil else {
            // The stage was already resolved (e.g. aborted on leave). Avoid
            // emitting a duplicate completion for the same `stage_id`.
            return
        }
        let elapsed = Int(currentDate().timeIntervalSince(attempt.startedAt) * 1000)
        let event = makeEvent(
            stage: attempt.stage,
            eventType: .completed,
            stageId: attempt.stageId,
            peerConnection: attempt.peerConnection,
            joinAttemptId: attempt.joinAttemptId,
            outcome: outcome,
            elapsedTime: max(0, elapsed),
            retryCount: retryCount,
            details: attempt.details.merging(details),
            failure: outcome == .failure ? failure : nil
        )
        deliver(event)
    }

    func abortPendingStages(failure: ClientEventFailure) async {
        let pending = activeAttempts.values
        activeAttempts.removeAll()
        for attempt in pending {
            let elapsed = Int(currentDate().timeIntervalSince(attempt.startedAt) * 1000)
            let event = makeEvent(
                stage: attempt.stage,
                eventType: .completed,
                stageId: attempt.stageId,
                peerConnection: attempt.peerConnection,
                joinAttemptId: attempt.joinAttemptId,
                outcome: .failure,
                elapsedTime: max(0, elapsed),
                retryCount: 0,
                details: attempt.details,
                failure: failure
            )
            deliver(event)
        }
    }

    // MARK: - Private

    /// Builds a ``ClientEvent`` with the common field set plus the supplied
    /// stage-specific fields.
    private func makeEvent(
        stage: ClientEventStage,
        eventType: ClientEventType,
        stageId: String?,
        peerConnection: ClientEventPeerConnection?,
        joinAttemptId: String? = nil,
        outcome: ClientEventOutcome? = nil,
        elapsedTime: Int? = nil,
        retryCount: Int? = nil,
        details: ClientEventStageDetails = .init(),
        failure: ClientEventFailure? = nil
    ) -> ClientEvent {
        let event = ClientEvent(
            callSessionId: details.callSessionId,
            elapsedTime: elapsedTime,
            eventSessionId: stageId,
            eventType: eventType.rawValue,
            iceState: details.iceState?.rawValue,
            id: context.callId,
            joinSuccessId: joinAttemptId ?? self.joinAttemptId,
            outcome: outcome?.rawValue,
            peerConnection: peerConnection?.rawValue,
            previouslyConnectedTimestamp: details.previouslyConnectedTimestamp,
            retryCountAttempt: retryCount,
            retryFailureCode: failure?.code,
            retryFailureReason: failure?.reason,
            sdkVersion: context.sdkVersion,
            sfuId: details.sfuId,
            stage: stage.rawValue,
            timestamp: currentDate(),
            userAgent: context.userAgent,
            userId: context.userId,
            userSessionId: details.userSessionId,
            wasPreviouslyConnected: details.wasPreviouslyConnected
        )
        // `type` is not part of the generated memberwise initializer, so set it
        // explicitly to carry the call type (`<call_type>`).
        event.type = context.callType
        return event
    }

    /// Schedules delivery of a single event in its own task.
    ///
    /// The task is tracked by the `disposableBag` and never awaited by the
    /// caller, so the join flow is not blocked. Because actors are reentrant at
    /// suspension points, the network/backoff `await` inside ``send(_:)`` does
    /// not block subsequent `beginStage`/`completeStage` calls.
    private func deliver(_ event: ClientEvent) {
        Task(disposableBag: disposableBag) { [weak self] in
            await self?.send(event)
        }
    }

    /// Performs delivery with the configured retry policy. Failures are
    /// swallowed once retries are exhausted.
    ///
    /// The retry loop is inlined (rather than using the shared `executeTask`)
    /// so the API call stays an actor-isolated call and the non-`Sendable`
    /// coordinator client never crosses an isolation boundary. Because the
    /// actor is reentrant at the `await` points, in-flight retries never block
    /// other reporting calls.
    private func send(_ event: ClientEvent) async {
        let request = ReportClientEventRequest(events: [event])
        var retries = 0
        while true {
            do {
                _ = try await api.reportClientCallEvent(reportClientEventRequest: request)
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

extension RetryPolicy {
    /// Retry policy for client event reporting.
    ///
    /// Up to 5 total delivery attempts with exponential backoff starting at
    /// 500 ms (500, 1000, 2000, 4000 ms). Combined with the default
    /// `shouldRetryError` (``Error/hasClientErrors``), `4xx` validation errors
    /// are not retried while `5xx`, network, and timeout errors are.
    static let clientEventReporting = RetryPolicy(
        maxRetries: 4,
        delay: { retries in 0.5 * pow(2, Double(retries)) }
    )
}
