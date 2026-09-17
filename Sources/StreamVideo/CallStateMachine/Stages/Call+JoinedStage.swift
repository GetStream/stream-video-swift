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
        /// Subscriptions are registered on the main actor in one task so
        /// capability state present before `.joined` is synced immediately,
        /// without waiting on a nested executor hop under parallel test load.
        private func execute() {
            guard let call = context.call else { return }
            Task(disposableBag: disposableBag, priority: .userInitiated) { @MainActor [weak self] in
                guard let self else { return }
                await call.callController.updateOwnCapabilities(
                    ownCapabilities: call.state.ownCapabilities
                )
                subscribeToCallSettingsUpdates(on: call)
                subscribeToOwnCapabilitiesChanges(on: call)
            }
        }

        /// Subscribes to call-settings changes while in the joined stage.
        ///
        /// Must run on the main actor because `CallState` is main-actor isolated.
        /// Each emitted value updates the local managers that coordinate
        /// camera/microphone behavior.
        ///
        /// - Parameter call: The call whose settings stream should be observed.
        @MainActor
        private func subscribeToCallSettingsUpdates(on call: Call) {
            call.state.$callSettings
                .receive(on: DispatchQueue.main)
                .sink { [weak call] in call?.updateCallSettingsManagers(with: $0) }
                .store(in: disposableBag)
        }

        /// Subscribes to own-capability changes while in the joined stage.
        ///
        /// Duplicated capability sets are filtered to avoid unnecessary backend
        /// updates. The current value is synced once when observation starts,
        /// then every subsequent change is forwarded to the call controller.
        ///
        /// - Parameter call: The call whose capability stream should be observed.
        @MainActor
        private func subscribeToOwnCapabilitiesChanges(on call: Call) {
            call.state.$ownCapabilities
                .removeDuplicates()
                .dropFirst()
                .sinkTask(storeIn: disposableBag) { [weak call] in
                    await call?
                        .callController
                        .updateOwnCapabilities(ownCapabilities: $0)
                }
                .store(in: disposableBag)
        }
    }
}
