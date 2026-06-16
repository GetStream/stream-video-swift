//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Reports the `WSJoin` client-event pair for an SFU join request.
///
/// The measured window is intentionally narrow: it starts after the join
/// request is sent and resolves when the SFU `JoinResponse` arrives or times
/// out. Peer-connection setup and media readiness are reported by later stages.
struct WebSocketJoinTelemetryReporter {

    private var stateAdapter: WebRTCStateAdapter?
    private var clientEventReporter: ClientEventReporting?

    private var details: ClientEventStageDetails?
    private var stageAttempt: ClientEventStageAttempt?

    /// Supplies the dependencies used to emit events for the active stage.
    ///
    /// `JoiningStage` owns this value and configures it for each stage instance
    /// before beginning a `WSJoin` attempt.
    mutating func configure(
        stateAdapter: WebRTCStateAdapter,
        clientEventReporter: ClientEventReporting
    ) {
        self.stateAdapter = stateAdapter
        self.clientEventReporter = clientEventReporter
    }

    /// Begins the `WSJoin` attempt and updates media-event details.
    ///
    /// - Parameters:
    ///   - sfuId: Identifier of the SFU that received the join request.
    ///   - callSessionId: Call session id from the coordinator join response.
    ///   - coordinatorConnectId: Id shared by the coordinator connect flow.
    mutating func begin(
        sfuId: String,
        callSessionId: String?,
        coordinatorConnectId: String
    ) async {
        guard let stateAdapter, let clientEventReporter else {
            log.warning("Invalid state to begin webSocket join attempt.")
            return
        }

        let details = ClientEventStageDetails(
            sfuId: sfuId,
            callSessionId: callSessionId,
            coordinatorConnectId: coordinatorConnectId
        )

        await stateAdapter.set(clientEventDetails: details)

        // Keep the stage focused on JoinRequest -> JoinResponse. Peer
        // connection and first-frame readiness are reported separately.
        let newStageAttempt = await clientEventReporter
            .beginStage(.wsJoin, peerConnection: nil, details: details)

        self.details = details
        self.stageAttempt = newStageAttempt
    }

    /// Completes the active `WSJoin` attempt as successful.
    ///
    /// - Parameter retryCount: Number of reconnect attempts made by the flow.
    mutating func complete(
        retryCount: Int
    ) async {
        guard let clientEventReporter, details != nil, let stageAttempt else {
            log.warning("Invalid state to complete webSocket join attempt.")
            return
        }

        await clientEventReporter.completeStage(
            stageAttempt,
            outcome: .success,
            retryCount: retryCount
        )

        self.details = nil
        self.stageAttempt = nil
    }

    /// Completes the active `WSJoin` attempt as failed.
    ///
    /// - Parameters:
    ///   - retryCount: Number of reconnect attempts made by the flow.
    ///   - error: Error that prevented receiving the SFU `JoinResponse`.
    mutating func fail(
        retryCount: Int,
        error: Error
    ) async {
        guard let clientEventReporter, let details, let stageAttempt else {
            log.warning("Invalid state to fail webSocket join attempt.")
            return
        }

        await clientEventReporter.completeStage(
            stageAttempt,
            outcome: .failure,
            retryCount: retryCount,
            details: details,
            failure: .init(error)
        )

        self.details = nil
        self.stageAttempt = nil
    }
}
