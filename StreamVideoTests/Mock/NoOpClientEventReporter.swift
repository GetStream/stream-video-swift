//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo

/// No-op fallback for focused tests that construct low-level WebRTC components
/// without a call-scoped reporter.
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
