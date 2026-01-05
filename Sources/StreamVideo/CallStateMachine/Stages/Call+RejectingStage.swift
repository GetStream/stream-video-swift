//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

extension Call.StateMachine.Stage {

    /// Creates a rejecting stage for a call with the given input.
    ///
    /// - Parameters:
    ///   - call: The call to be rejected
    ///   - input: The input containing rejection parameters
    /// - Returns: A new `RejectingStage` instance
    static func rejecting(
        _ call: Call,
        input: Context.Input
    ) -> Call.StateMachine.Stage {
        RejectingStage(
            .init(
                call: call,
                input: input
            )
        )
    }
}

extension Call.StateMachine.Stage {

    /// Represents the rejecting stage in the call state machine.
    final class RejectingStage: Call.StateMachine.Stage, @unchecked Sendable {
        @Injected(\.callCache) private var callCache
        @Injected(\.streamVideo) private var streamVideo

        private let disposableBag = DisposableBag()

        /// Creates a new rejecting stage with the provided context.
        ///
        /// - Parameter context: The call context containing necessary state
        init(
            _ context: Context
        ) {
            super.init(id: .rejecting, context: context)
        }

        /// Handles state transitions to the rejecting stage.
        ///
        /// Valid transitions:
        /// - From: IdleStage
        /// - To: RejectedStage
        ///
        /// - Parameter previousStage: The stage transitioning from
        /// - Returns: Self if transition is valid, nil otherwise
        override func transition(
            from previousStage: Call.StateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .idle, .joined:
                execute()
                return self
            default:
                return nil
            }
        }

        // MARK: - Private Helpers

        /// Executes the call rejection process asynchronously.
        private func execute() {
            Task(disposableBag: disposableBag) { [weak self] in
                guard let self else { return }

                try? Task.checkCancellation()

                guard
                    let call = context.call,
                    case let .rejecting(input) = context.input
                else {
                    transitionErrorOrLog(ClientError("Invalid input to reject call."))
                    return
                }

                do {
                    try Task.checkCancellation()

                    let response = try await call.coordinatorClient.rejectCall(
                        type: call.callType,
                        id: call.callId,
                        rejectCallRequest: .init(reason: input.reason)
                    )

                    try Task.checkCancellation()

                    if streamVideo.state.ringingCall?.cId == call.cId {
                        await Task(disposableBag: disposableBag) { @MainActor [weak streamVideo] in
                            streamVideo?.state.ringingCall = nil
                        }.value
                    }

                    try Task.checkCancellation()

                    callCache.remove(for: call.cId)

                    input.deliverySubject.send(response)

                    transitionOrError(.rejected(context, response: response))
                } catch {
                    input.deliverySubject.send(completion: .failure(error))
                    transitionErrorOrLog(error)
                }
            }
        }
    }
}
