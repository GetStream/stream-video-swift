//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Validates caller cancellation before the rejection state machine runs.
protocol OutgoingRingCancellationValidating: Sendable {
    @MainActor
    func validate(call: Call, reason: String?, stateMachine: Call.StateMachine) async throws
}

/// Prevents the creator from cancelling a ring already accepted by a callee.
final class OutgoingRingCancellationValidator: OutgoingRingCancellationValidating {

    @MainActor
    func validate(call: Call, reason: String?, stateMachine: Call.StateMachine) async throws {
        let stage = stateMachine.currentStage
        guard
            reason == nil || reason == RejectCallRequest.Reason.cancel,
            call.state.createdBy?.id == call.streamVideo.user.id,
            let sessionId = call.state.session?.id,
            !isRejectionStarted(stage)
        else { return }

        if !hasAcceptedCallee(call) {
            guard try await refreshRingState(
                call,
                sessionId: sessionId,
                stage: stage,
                stateMachine: stateMachine
            ) else { return }
        }

        guard !hasAcceptedCallee(call) else {
            throw ClientError("Cannot cancel a call that has been accepted.")
        }
    }

    @MainActor
    private func hasAcceptedCallee(_ call: Call) -> Bool {
        call.state.session?.acceptedBy.keys.contains { $0 != call.streamVideo.user.id } == true
    }

    /// Refreshes acceptance without applying a response to a changed lifecycle.
    @MainActor
    private func refreshRingState(
        _ call: Call,
        sessionId: String,
        stage: Call.StateMachine.Stage,
        stateMachine: Call.StateMachine
    ) async throws -> Bool {
        // The accept event may not have reached this socket yet.
        let response = try await call.getRingState(callSessionId: sessionId)
        try Task.checkCancellation()
        guard call.state.session?.id == sessionId else {
            throw CancellationError()
        }

        let currentStage = stateMachine.currentStage
        // Let reject() share an in-flight or completed rejection.
        guard !isRejectionStarted(currentStage) else { return false }
        guard currentStage === stage else {
            throw CancellationError()
        }

        call.state.update(from: response)
        return true
    }

    private func isRejectionStarted(_ stage: Call.StateMachine.Stage) -> Bool {
        stage.id == .rejecting || stage.id == .rejected
    }
}
