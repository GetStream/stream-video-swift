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

    private let context: Context
    private let currentDate: @Sendable () -> Date
    private let delivery: ClientEventDelivery
    private let disposableBag = DisposableBag()

    /// The id shared across all events of the active join attempt. Regenerated
    /// by ``reportJoinInitiated()`` on every new attempt.
    private(set) var joinAttemptId: String = UUID().uuidString.lowercased()

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
        self.context = context
        self.currentDate = currentDate
        self.delivery = .init(api: api, retryPolicy: retryPolicy)
    }

    // MARK: - ClientEventReporting

    func reportJoinInitiated(details: ClientEventStageDetails) async {
        // A new attempt supersedes the previous one. Drop any stage attempts
        // that never completed so they are not later resolved against the new
        // attempt id; the backend treats their missing completion as a failure.
        activeAttempts.removeAll()
        joinAttemptId = UUID().uuidString.lowercased()
        let event = makeEvent(
            stage: .joinInitiated,
            eventType: .initiated,
            stageId: nil,
            peerConnection: nil,
            details: details
        )
        deliver(event)
    }

    /// Reports a single initiated event without tracking a pending completion.
    func reportEvent(
        _ stage: ClientEventStage,
        details: ClientEventStageDetails
    ) async {
        let event = makeEvent(
            stage: stage,
            eventType: .initiated,
            stageId: UUID().uuidString.lowercased(),
            peerConnection: nil,
            details: details
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
            stageId: UUID().uuidString.lowercased(),
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

    func updateStage(
        _ attempt: ClientEventStageAttempt,
        details: ClientEventStageDetails
    ) async {
        guard let stored = activeAttempts[attempt.stageId] else {
            // Already resolved (or aborted); nothing to keep current.
            return
        }
        activeAttempts[attempt.stageId] = ClientEventStageAttempt(
            stage: stored.stage,
            stageId: stored.stageId,
            peerConnection: stored.peerConnection,
            joinAttemptId: stored.joinAttemptId,
            startedAt: stored.startedAt,
            details: stored.details.merging(details)
        )
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
            cameraPermissionStatus: details.cameraPermissionStatus?.rawValue,
            coordinatorConnectId: details.coordinatorConnectId,
            elapsedTime: elapsedTime,
            eventType: eventType.rawValue,
            iceState: details.iceState?.rawValue,
            id: context.callId,
            joinAttemptId: stage == .coordinatorWS ? nil : joinAttemptId ?? self.joinAttemptId,
            joinReason: details.joinReason?.rawValue,
            microphonePermissionStatus: details.microphonePermissionStatus?.rawValue,
            outcome: outcome?.rawValue,
            peerConnection: peerConnection?.rawValue,
            previouslyConnectedTimestamp: details.previouslyConnectedTimestamp,
            retryCountAttempt: retryCount,
            retryFailureCode: failure?.code,
            retryFailureReason: failure?.reason,
            screenShareStatus: details.screenShareStatus?.rawValue,
            sdkVersion: context.sdkVersion,
            sfuId: details.sfuId,
            stage: stage.rawValue,
            stageId: stageId,
            timestamp: currentDate(),
            trackId: details.trackId,
            userAgent: context.userAgent,
            userId: context.userId,
            wasPreviouslyConnected: details.wasPreviouslyConnected
        )
        // `type` is not part of the generated memberwise initializer, so set it
        // explicitly to carry the call type (`<call_type>`).
        event.type = context.callType
        return event
    }

    /// Schedules delivery of a single event in its own task.
    ///
    /// Delivery intentionally is not tied to this reporter's `disposableBag`.
    /// A call can be deallocated immediately after leaving while the final
    /// `completed/failure` event is still in flight; retaining the delivery task
    /// independently gives that event a chance to reach the backend.
    private func deliver(_ event: ClientEvent) {
        let delivery = delivery
        Task {
            await delivery.send(event)
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

extension ReportClientEventRequest: CustomStringConvertible {
    public var description: String {
        var result = "{"
        result += " count: \(events.endIndex)"
        result += ", events: \(events)"
        result += " }"
        return result
    }
}

extension ClientEvent: CustomStringConvertible {
    public var description: String {
        var result = "{"
        var separator = " "

        func append<T>(label: String, value: T?) {
            guard let value else { return }
            result += "\(separator)\(label): \(value)"
            separator = ", "
        }

        append(label: "callSessionId", value: callSessionId)
        append(label: "cameraPermissionStatus", value: cameraPermissionStatus)
        append(label: "coordinatorConnectId", value: coordinatorConnectId)
        append(label: "elapsedTime", value: elapsedTime)
        append(label: "eventType", value: eventType)
        append(label: "iceState", value: iceState)
        append(label: "id", value: id)
        append(label: "joinAttemptId", value: joinAttemptId)
        append(label: "microphonePermissionStatus", value: microphonePermissionStatus)
        append(label: "outcome", value: outcome)
        append(label: "peerConnection", value: peerConnection)
        append(label: "previouslyConnectedTimestamp", value: previouslyConnectedTimestamp)
        append(label: "retryCountAttempt", value: retryCountAttempt)
        append(label: "retryFailureCode", value: retryFailureCode)
        append(label: "retryFailureReason", value: retryFailureReason)
        append(label: "screenShareStatus", value: screenShareStatus)
        append(label: "sdkVersion", value: sdkVersion)
        append(label: "sfuId", value: sfuId)
        append(label: "stage", value: stage)
        append(label: "stageId", value: stageId)
        append(label: "timestamp", value: timestamp)
        append(label: "trackId", value: trackId)
        append(label: "type", value: type)
        append(label: "userAgent", value: userAgent)
        append(label: "userId", value: userId)
        append(label: "wasPreviouslyConnected", value: wasPreviouslyConnected)
        result += " }"

        return result
    }
}
