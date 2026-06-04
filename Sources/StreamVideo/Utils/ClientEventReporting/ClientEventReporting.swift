//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A handle returned by ``ClientEventReporting/beginStage(_:peerConnection:details:)``
/// that carries the information required to report the matching `completed`
/// event.
///
/// The `stageId` is shared between the `initiated` and `completed` events of a
/// single stage attempt so the backend can correlate them.
struct ClientEventStageAttempt: Sendable, Equatable {
    /// The stage this attempt belongs to.
    let stage: ClientEventStage
    /// The UUID shared by the `initiated` / `completed` pair (`event_session_id`).
    let stageId: String
    /// The peer connection this attempt reports on (only for
    /// ``ClientEventStage/peerConnectionConnect``).
    let peerConnection: ClientEventPeerConnection?
    /// The join attempt id in effect when the stage started.
    let joinAttemptId: String
    /// The moment the stage attempt was initiated, used to compute the
    /// `elapsed_time` of the completion event.
    let startedAt: Date
    /// The stage-specific fields captured at initiation, reused on completion
    /// when not overridden.
    let details: ClientEventStageDetails
}

/// Stage-specific fields that accompany an event in addition to the common set.
///
/// Most fields are only required on failure completion events, but some (such
/// as `wasPreviouslyConnected` and `peerConnection`) are required on every
/// ``ClientEventStage/peerConnectionConnect`` event.
struct ClientEventStageDetails: Sendable, Equatable {
    /// Identifier of the SFU the client is connecting to.
    var sfuId: String?
    /// Call session id associated with the attempt.
    var callSessionId: String?
    /// Per-user session id associated with the attempt.
    var userSessionId: String?
    /// Whether the ICE connection had been established earlier in the same
    /// session. Required on every `PeerConnectionConnect` event.
    var wasPreviouslyConnected: Bool?
    /// UTC timestamp at which the ICE connection was established earlier in the
    /// session, when applicable.
    var previouslyConnectedTimestamp: Date?
    /// Terminal ICE state. Required on `PeerConnectionConnect` failure.
    var iceState: ClientEventICEState?

    init(
        sfuId: String? = nil,
        callSessionId: String? = nil,
        userSessionId: String? = nil,
        wasPreviouslyConnected: Bool? = nil,
        previouslyConnectedTimestamp: Date? = nil,
        iceState: ClientEventICEState? = nil
    ) {
        self.sfuId = sfuId
        self.callSessionId = callSessionId
        self.userSessionId = userSessionId
        self.wasPreviouslyConnected = wasPreviouslyConnected
        self.previouslyConnectedTimestamp = previouslyConnectedTimestamp
        self.iceState = iceState
    }

    /// Returns a copy where non-nil fields of `other` override this value.
    func merging(_ other: ClientEventStageDetails) -> ClientEventStageDetails {
        .init(
            sfuId: other.sfuId ?? sfuId,
            callSessionId: other.callSessionId ?? callSessionId,
            userSessionId: other.userSessionId ?? userSessionId,
            wasPreviouslyConnected: other.wasPreviouslyConnected ?? wasPreviouslyConnected,
            previouslyConnectedTimestamp: other.previouslyConnectedTimestamp ?? previouslyConnectedTimestamp,
            iceState: other.iceState ?? iceState
        )
    }
}

/// Reports client-side join-lifecycle events to the backend so the user's
/// progress through the join flow can be tracked and reconciled server-side.
///
/// Reporting is best-effort and fire-and-forget: callers are never blocked on
/// network delivery and delivery failures never surface to the join flow.
protocol ClientEventReporting: Sendable {

    /// The join attempt id (`join_success_id`) currently shared across the
    /// events of the active join attempt.
    var joinAttemptId: String { get async }

    /// Begins a new join attempt.
    ///
    /// Generates a fresh ``joinAttemptId`` and reports a
    /// ``ClientEventStage/joinInitiated`` event. Called for fresh joins as well
    /// as full rejoins and migrations, which are treated as new join attempts.
    /// Fast reconnects must **not** call this.
    func reportJoinInitiated() async

    /// Reports a stage `initiated` event and returns a handle used to report
    /// the matching `completed` event.
    ///
    /// - Parameters:
    ///   - stage: The stage that is starting.
    ///   - peerConnection: The peer connection the stage reports on, when
    ///     applicable.
    ///   - details: Stage-specific fields known at initiation.
    /// - Returns: A handle to pass to
    ///   ``completeStage(_:outcome:retryCount:details:failure:)``.
    @discardableResult
    func beginStage(
        _ stage: ClientEventStage,
        peerConnection: ClientEventPeerConnection?,
        details: ClientEventStageDetails
    ) async -> ClientEventStageAttempt

    /// Reports the `completed` event matching a previously begun stage attempt.
    ///
    /// - Parameters:
    ///   - attempt: The handle returned by
    ///     ``beginStage(_:peerConnection:details:)``.
    ///   - outcome: Whether the stage resolved with success or failure.
    ///   - retryCount: Total in-stage retries made before resolving.
    ///   - details: Stage-specific fields known at completion; non-nil fields
    ///     override those captured at initiation.
    ///   - failure: The failure description, required when `outcome == .failure`.
    func completeStage(
        _ attempt: ClientEventStageAttempt,
        outcome: ClientEventOutcome,
        retryCount: Int,
        details: ClientEventStageDetails,
        failure: ClientEventFailure?
    ) async

    /// Completes every stage that was begun but not yet completed as a failure.
    ///
    /// Used when the user leaves the call or the backend ends it while a join
    /// stage is still in progress, so the backend records an explicit failure
    /// instead of inferring one from a missing completion.
    ///
    /// - Parameter failure: The failure to attach (e.g. `CLIENT_ABORTED` when
    ///   the user left, `BACKEND_LEAVE` when the backend ended the call).
    func abortPendingStages(failure: ClientEventFailure) async
}

extension ClientEventReporting {

    /// Convenience that begins a stage without peer-connection or extra details.
    @discardableResult
    func beginStage(
        _ stage: ClientEventStage
    ) async -> ClientEventStageAttempt {
        await beginStage(stage, peerConnection: nil, details: .init())
    }

    /// Convenience that begins a stage for a specific peer connection.
    @discardableResult
    func beginStage(
        _ stage: ClientEventStage,
        peerConnection: ClientEventPeerConnection?
    ) async -> ClientEventStageAttempt {
        await beginStage(stage, peerConnection: peerConnection, details: .init())
    }

    /// Convenience that completes a stage with the given outcome.
    func completeStage(
        _ attempt: ClientEventStageAttempt,
        outcome: ClientEventOutcome
    ) async {
        await completeStage(
            attempt,
            outcome: outcome,
            retryCount: 0,
            details: .init(),
            failure: nil
        )
    }

    /// Convenience that completes a stage with the given outcome and retry count.
    func completeStage(
        _ attempt: ClientEventStageAttempt,
        outcome: ClientEventOutcome,
        retryCount: Int
    ) async {
        await completeStage(
            attempt,
            outcome: outcome,
            retryCount: retryCount,
            details: .init(),
            failure: nil
        )
    }

    /// Convenience that completes a stage as a failure.
    func completeStage(
        _ attempt: ClientEventStageAttempt,
        retryCount: Int,
        details: ClientEventStageDetails = .init(),
        failure: ClientEventFailure
    ) async {
        await completeStage(
            attempt,
            outcome: .failure,
            retryCount: retryCount,
            details: details,
            failure: failure
        )
    }
}
