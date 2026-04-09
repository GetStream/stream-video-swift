//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension Call.StateMachine.Stage {

    /// Creates a joining stage for a call with the given input.
    ///
    /// - Parameters:
    ///   - call: The call to be joined
    ///   - input: The input containing join parameters
    /// - Returns: A new `JoiningStage` instance
    static func joining(
        _ call: Call,
        input: Context.Input
    ) -> Call.StateMachine.Stage {
        JoiningStage(
            .init(
                call: call,
                input: input
            )
        )
    }
}

extension Call.StateMachine.Stage {

    /// Represents the joining stage in the call state machine.
    final class JoiningStage: Call.StateMachine.Stage, @unchecked Sendable {
        @Injected(\.streamVideo) private var streamVideo

        private let disposableBag = DisposableBag()
        private var iterations = 0

        /// Creates a new joining stage with the provided context.
        ///
        /// - Parameter context: The call context containing necessary state
        init(
            _ context: Context
        ) {
            super.init(id: .joining, context: context)
        }

        /// Handles state transitions to the joining stage.
        ///
        /// Valid transitions:
        /// - From: IdleStage, AcceptedStage, JoiningStage
        /// - To: JoinedStage, ErrorStage
        ///
        /// - Parameter previousStage: The stage transitioning from
        /// - Returns: Self if transition is valid, nil otherwise
        override func transition(
            from previousStage: Call.StateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .idle, .accepted, .joining:
                execute()
                return self
            default:
                return nil
            }
        }

        // MARK: - Private Helpers

        /// Executes the call joining process asynchronously.
        private func execute() {
            Task(disposableBag: disposableBag) { [weak self] in
                guard let self else { return }

                try? Task.checkCancellation()

                guard
                    let call = context.call,
                    case let .join(input) = context.input
                else {
                    transitionErrorOrLog(ClientError("Invalid input to join call."))
                    return
                }

                log.debug("Will attempt joining call id:\(call.callId) type:\(call.callType) with input: \(input).")

                do {
                    let response = try await executeJoin(call: call, input: input)
                    transitionOrError(.joined(context, response: response))
                } catch let error as CallJoinInterceptionError {
                    // Interception failures are terminal for this join attempt,
                    // so they are surfaced to the original caller without
                    // entering the retry branch below.
                    // Record the failure in the tracing pipeline before the
                    // stage transitions into the error state.
                    await call.callController.trace(.init(error))
                    input.deliverySubject.send(completion: .failure(error))
                    transitionErrorOrLog(error)
                } catch {
                    var input = input
                    input.currentNumberOfRetries += 1

                    if input.currentNumberOfRetries < input.retryPolicy.maxRetries {
                        let delay = UInt64((input.retryPolicy.delay(input.currentNumberOfRetries)) * 1_000_000_000)
                        log.error(
                            "Joining call id:\(call.callId) type:\(call.callType) failed. Will retry after a delay.",
                            error: error
                        )
                        try? await Task.sleep(nanoseconds: delay)
                        transitionOrError(.joining(call, input: .join(input)))
                    } else {
                        input.deliverySubject.send(completion: .failure(error))
                        transitionErrorOrLog(error)
                    }
                }
            }
        }

        /// Executes the join call operation with retry logic.
        /// The call result is returned both as a stage-local response and through the
        /// shared `join` completion channel.
        ///
        /// Before the stage publishes the join result, it gives the optional
        /// join interceptor a bounded window to perform app-specific readiness
        /// work.
        ///
        /// - Parameters:
        ///   - call: The call to join.
        ///   - input: The join parameters.
        /// - Returns: The join call response.
        private func executeJoin(
            call: Call,
            input: Context.JoinInput
        ) async throws -> JoinCallResponse {
            try Task.checkCancellation()

            let response = try await call.callController.joinCall(
                create: input.create,
                callSettings: input.callSettings,
                options: input.options,
                ring: input.ring,
                notify: input.notify,
                source: input.source,
                policy: input.policy
            )

            try Task.checkCancellation()

            await call.state.update(from: response)

            try Task.checkCancellation()

            let updated = await call.state.callSettings

            call.updateCallSettingsManagers(with: updated)

            try Task.checkCancellation()

            // Use the shared call configuration so production and test builds
            // can tune interception timing independently.
            try await interceptJoinIfNeeded(
                input.joinInterceptor,
                call: call,
                timeout: CallConfiguration.timeout.joinInterception
            )

            try Task.checkCancellation()

            await Task(disposableBag: disposableBag) { @MainActor [weak streamVideo] in
                streamVideo?.state.activeCall = call
            }.value

            try Task.checkCancellation()

            input.deliverySubject.send(response)

            call.callController.observeWebRTCStateUpdated()

            return response
        }

        /// Runs the optional join interceptor without letting it block the join
        /// flow indefinitely.
        ///
        /// If the interceptor completes first, the join flow continues
        /// immediately. If the timeout completes first, the interceptor is
        /// cancelled and the join continues. If the interceptor throws before
        /// timing out, the error is wrapped and surfaced to the caller.
        ///
        /// - Parameters:
        ///   - interceptor: The interceptor provided by the integrator.
        ///   - call: The call that is about to become active.
        ///   - timeout: The maximum number of seconds the interceptor may delay
        ///     the join flow.
        /// - Throws: A `CallJoinInterceptionError` when the interceptor throws.
        private func interceptJoinIfNeeded(
            _ interceptor: CallJoinIntercepting?,
            call: Call,
            timeout: TimeInterval
        ) async throws {
            guard let interceptor else {
                return
            }

            do {
                try await withThrowingTaskGroup(of: Void.self) { group in
                    group.addTask {
                        try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                    }

                    group.addTask {
                        try await interceptor.callReadyToJoin(call)
                    }

                    try await group.next()

                    group.cancelAll()
                }
            } catch {
                throw CallJoinInterceptionError(with: error)
            }
        }
    }
}
