//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

extension Call.StateMachine.Stage {

    /// Creates an accepting stage for a call with the given input.
    ///
    /// - Parameters:
    ///   - call: The call to be accepted
    ///   - input: The input containing acceptance parameters
    /// - Returns: A new `AcceptingStage` instance
    static func accepting(
        _ call: Call,
        input: Context.Input
    ) -> Call.StateMachine.Stage {
        AcceptingStage(
            .init(call: call, input: input)
        )
    }
}

extension Call.StateMachine.Stage {

    /// Represents the accepting stage in the call state machine.
    final class AcceptingStage: Call.StateMachine.Stage, @unchecked Sendable {
        /// CallKit bridge used to promote an already reported incoming system
        /// call when the user accepts from the app's own incoming-call screen.
        ///
        /// If CallKit does not know the call, the bridge is a no-op and the
        /// normal backend accept continues. If CallKit does know the call, this
        /// asks CallKit to perform `CXAnswerCallAction` before the backend
        /// accept so the system UI and audio session move to the in-call state.
        @Injected(\.callKitService) private var callKitService

        private let disposableBag = DisposableBag()

        /// Creates a new accepting stage with the provided context.
        ///
        /// - Parameter context: The call context containing necessary state
        init(
            _ context: Context
        ) {
            super.init(id: .accepting, context: context)
        }

        /// Handles state transitions to the accepting stage.
        ///
        /// Valid transitions:
        /// - From: IdleStage
        /// - To: AcceptedStage
        ///
        /// - Parameter previousStage: The stage transitioning from
        /// - Returns: Self if transition is valid, nil otherwise
        override func transition(
            from previousStage: Call.StateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .idle:
                execute()
                return self
            default:
                return nil
            }
        }

        // MARK: - Private Helpers

        /// Executes the call acceptance process asynchronously.
        private func execute() {
            Task(disposableBag: disposableBag) { [weak self] in
                guard let self else { return }

                try? Task.checkCancellation()

                guard
                    let call = context.call,
                    case let .accepting(input) = context.input
                else {
                    transitionErrorOrLog(ClientError("Invalid input to accept call."))
                    return
                }

                do {
                    try Task.checkCancellation()

                    // Keep CallKit in sync before the backend accept. This
                    // covers foreground incoming calls that were already
                    // reported to CallKit but accepted from the app UI instead
                    // of the native CallKit answer affordance.
                    try await callKitService.reportExternalIncomingCallConnecting(call)

                    try Task.checkCancellation()

                    let response = try await call.coordinatorClient.acceptCall(
                        type: call.callType,
                        id: call.callId
                    )

                    input.send(response)

                    transitionOrError(.accepted(context, response: response))
                } catch {
                    input.send(completion: .failure(error))
                    transitionErrorOrLog(error)
                }
            }
        }
    }
}
