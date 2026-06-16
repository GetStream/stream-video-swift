//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo

/// Recording test double for ``ClientEventReporting`` used to assert how the
/// join flow drives client-event reporting.
actor MockClientEventReporter: ClientEventReporting {

    struct BegunStage: Sendable {
        var stage: ClientEventStage
        var peerConnection: ClientEventPeerConnection?
        var details: ClientEventStageDetails
        var attempt: ClientEventStageAttempt
    }

    struct CompletedStage: Sendable {
        var attempt: ClientEventStageAttempt
        var outcome: ClientEventOutcome
        var retryCount: Int
        var details: ClientEventStageDetails
        var failure: ClientEventFailure?
    }

    struct ReportedEvent: Sendable {
        var stage: ClientEventStage
        var details: ClientEventStageDetails
    }

    private(set) var joinAttemptId: String = UUID().uuidString.lowercased()
    private(set) var reportJoinInitiatedCallCount = 0
    private(set) var reportedEvents: [ReportedEvent] = []
    private(set) var begunStages: [BegunStage] = []
    private(set) var completedStages: [CompletedStage] = []
    private(set) var abortedFailures: [ClientEventFailure] = []

    func reportJoinInitiated() async {
        reportJoinInitiatedCallCount += 1
        joinAttemptId = UUID().uuidString.lowercased()
    }

    func reportEvent(
        _ stage: ClientEventStage,
        details: ClientEventStageDetails
    ) async {
        reportedEvents.append(.init(stage: stage, details: details))
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
            startedAt: Date(),
            details: details
        )
        begunStages.append(
            .init(
                stage: stage,
                peerConnection: peerConnection,
                details: details,
                attempt: attempt
            )
        )
        return attempt
    }

    func completeStage(
        _ attempt: ClientEventStageAttempt,
        outcome: ClientEventOutcome,
        retryCount: Int,
        details: ClientEventStageDetails,
        failure: ClientEventFailure?
    ) async {
        completedStages.append(
            .init(
                attempt: attempt,
                outcome: outcome,
                retryCount: retryCount,
                details: details,
                failure: failure
            )
        )
    }

    func abortPendingStages(failure: ClientEventFailure) async {
        abortedFailures.append(failure)
    }
}
