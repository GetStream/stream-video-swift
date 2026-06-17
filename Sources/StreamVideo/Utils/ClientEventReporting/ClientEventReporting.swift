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
    /// The UUID shared by the `initiated` / `completed` pair (`stage_id`).
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
    /// Coordinator connection id shared by the active coordinator flow.
    var coordinatorConnectId: String?
    /// Reason that triggered the coordinator join.
    var joinReason: ClientEventJoinReason?
    /// Media track id attached to first-frame events.
    var trackId: String?
    /// Microphone permission status for media-device permission events.
    var microphonePermissionStatus: ClientEventPermissionStatus?
    /// Camera permission status for media-device permission events.
    var cameraPermissionStatus: ClientEventPermissionStatus?
    /// Screen-share permission status for media-device permission events.
    var screenShareStatus: ClientEventPermissionStatus?
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
        coordinatorConnectId: String? = nil,
        joinReason: ClientEventJoinReason? = nil,
        trackId: String? = nil,
        microphonePermissionStatus: ClientEventPermissionStatus? = nil,
        cameraPermissionStatus: ClientEventPermissionStatus? = nil,
        screenShareStatus: ClientEventPermissionStatus? = nil,
        wasPreviouslyConnected: Bool? = nil,
        previouslyConnectedTimestamp: Date? = nil,
        iceState: ClientEventICEState? = nil
    ) {
        self.sfuId = sfuId
        self.callSessionId = callSessionId
        self.coordinatorConnectId = coordinatorConnectId
        self.joinReason = joinReason
        self.trackId = trackId
        self.microphonePermissionStatus = microphonePermissionStatus
        self.cameraPermissionStatus = cameraPermissionStatus
        self.screenShareStatus = screenShareStatus
        self.wasPreviouslyConnected = wasPreviouslyConnected
        self.previouslyConnectedTimestamp = previouslyConnectedTimestamp
        self.iceState = iceState
    }

    /// Returns a copy where non-nil fields of `other` override this value.
    func merging(_ other: ClientEventStageDetails) -> ClientEventStageDetails {
        .init(
            sfuId: other.sfuId ?? sfuId,
            callSessionId: other.callSessionId ?? callSessionId,
            coordinatorConnectId: other.coordinatorConnectId ?? coordinatorConnectId,
            joinReason: other.joinReason ?? joinReason,
            trackId: other.trackId ?? trackId,
            microphonePermissionStatus: other.microphonePermissionStatus
                ?? microphonePermissionStatus,
            cameraPermissionStatus: other.cameraPermissionStatus ?? cameraPermissionStatus,
            screenShareStatus: other.screenShareStatus ?? screenShareStatus,
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

    /// The join attempt id (`join_attempt_id`) currently shared across the
    /// events of the active join attempt.
    var joinAttemptId: String { get async }

    /// Begins a new join attempt.
    ///
    /// Generates a fresh ``joinAttemptId`` and reports a
    /// ``ClientEventStage/joinInitiated`` event. Called for fresh joins as well
    /// as full rejoins and migrations, which are treated as new join attempts.
    /// Fast reconnects must **not** call this.
    func reportJoinInitiated(details: ClientEventStageDetails) async

    /// Reports a single `initiated` event that has no matching completion.
    ///
    /// Used for spec stages whose outcome is represented by stage-specific
    /// fields instead of an `initiated` / `completed` pair.
    func reportEvent(
        _ stage: ClientEventStage,
        details: ClientEventStageDetails
    ) async

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

    /// Convenience that reports a `JoinInitiated` event without extra details.
    func reportJoinInitiated() async {
        await reportJoinInitiated(details: .init())
    }

    /// Convenience that reports a single event without extra details.
    func reportEvent(_ stage: ClientEventStage) async {
        await reportEvent(stage, details: .init())
    }

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

/// No-op fallback used by low-level adapters constructed without a call
/// reporter, mostly in focused unit tests.
actor NoOpClientEventReporter: ClientEventReporting {
    /// Current no-op join attempt identifier.
    private(set) var joinAttemptId: String = UUID().uuidString.lowercased()

    /// Starts a no-op join attempt.
    func reportJoinInitiated(details: ClientEventStageDetails) async {
        joinAttemptId = UUID().uuidString.lowercased()
    }

    /// Drops single-event reports.
    func reportEvent(
        _ stage: ClientEventStage,
        details: ClientEventStageDetails
    ) async {}

    /// Returns a synthetic stage attempt without delivery.
    @discardableResult
    func beginStage(
        _ stage: ClientEventStage,
        peerConnection: ClientEventPeerConnection?,
        details: ClientEventStageDetails
    ) async -> ClientEventStageAttempt {
        .init(
            stage: stage,
            stageId: UUID().uuidString.lowercased(),
            peerConnection: peerConnection,
            joinAttemptId: joinAttemptId,
            startedAt: Date(),
            details: details
        )
    }

    /// Drops stage completions.
    func completeStage(
        _ attempt: ClientEventStageAttempt,
        outcome: ClientEventOutcome,
        retryCount: Int,
        details: ClientEventStageDetails,
        failure: ClientEventFailure?
    ) async {}

    /// Drops pending-stage aborts.
    func abortPendingStages(failure: ClientEventFailure) async {}
}
