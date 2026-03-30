//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension Call.StateMachine.Stage {

    /// Creates a joined stage for the provided call with the specified response.
    ///
    /// - Parameters:
    ///   - call: The associated `Call` object.
    ///   - response: The `JoinCallResponse` object.
    /// - Returns: A `JoinedStage` instance.
    static func joined(
        _ context: Context,
        response: JoinCallResponse
    ) -> Call.StateMachine.Stage {
        JoinedStage(
            .init(
                call: context.call,
                output: .joined(response)
            )
        )
    }
}

extension Call.StateMachine.Stage {

    /// A class representing the joined stage in the `StreamCallStateMachine`.
    final class JoinedStage: Call.StateMachine.Stage, @unchecked Sendable {

        /// Holds subscriptions that are active while the state machine is in the
        /// joined stage.
        ///
        /// Keeping a stage-scoped bag ensures subscriptions are started only
        /// after a successful `.joining -> .joined` transition and are released
        /// together with the stage.
        private let disposableBag = DisposableBag()

        /// Initializes a new joined stage with the provided call and response.
        ///
        /// - Parameters:
        ///   - call: The associated `Call` object.
        ///   - response: The `JoinCallResponse` object.
        init(
            _ context: Context
        ) {
            super.init(id: .joined, context: context)
        }

        /// Handles the transition from the previous stage to this stage.
        ///
        /// This method defines valid transitions for the `JoinedStage`.
        ///
        /// - Parameter previousStage: The previous stage.
        /// - Returns: The new stage if the transition is valid, otherwise `nil`.
        ///
        /// - Valid Transition:
        ///   - From: `JoiningStage`
        ///   - To: `JoinedStage`
        override func transition(
            from previousStage: Call.StateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .joining:
                execute()
                return self
            default:
                return nil
            }
        }

        // MARK: - Private Helpers

        /// Starts joined-stage side effects after a valid stage transition.
        ///
        /// The method subscribes to call settings and capability updates so the
        /// call controller and media managers stay aligned with live call state.
        private func execute() {
            Task(disposableBag: disposableBag) { [weak self] in
                guard let self, let call = context.call else { return }
                await subscribeToCallSettingsUpdates(on: call)
                await subscribeToOwnCapabilitiesChanges(on: call)
            }
        }

        /// Subscribes to call-settings changes while in the joined stage.
        ///
        /// The publisher is created on the main actor because `CallState` is
        /// main-actor isolated. Each emitted value updates the local managers
        /// that coordinate camera/microphone behavior.
        ///
        /// - Parameter call: The call whose settings stream should be observed.
        private func subscribeToCallSettingsUpdates(on call: Call) async {
            let publisher = await MainActor.run {
                call.state.$callSettings.eraseToAnyPublisher()
            }
            publisher
                .sink { [weak call] in call?.updateCallSettingsManagers(with: $0) }
                .store(in: disposableBag)
        }

        /// Subscribes to own-capability changes while in the joined stage.
        ///
        /// Duplicated capability sets are filtered to avoid unnecessary backend
        /// updates. Every effective change is forwarded to the call controller
        /// so permission-dependent media actions stay in sync.
        ///
        /// - Parameter call: The call whose capability stream should be observed.
        private func subscribeToOwnCapabilitiesChanges(on call: Call) async {
            let publisher = await MainActor.run {
                call.state.$ownCapabilities
                    .removeDuplicates()
                    .eraseToAnyPublisher()
            }
            publisher
                .sinkTask(storeIn: disposableBag) { [weak call] in
                    await call?
                        .callController
                        .updateOwnCapabilities(ownCapabilities: $0)
                }
                .store(in: disposableBag)
        }
    }
}
