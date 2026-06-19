//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension WebRTCCoordinator.StateMachine.Stage {

    /// Creates and returns a migrated stage for the WebRTC coordinator state
    /// machine.
    /// - Parameter context: The context for the migrated stage.
    /// - Returns: A `MigratedStage` instance representing the migrated state of
    ///   the WebRTC coordinator.
    static func migrated(
        _ context: Context
    ) -> WebRTCCoordinator.StateMachine.Stage {
        MigratedStage(
            context
        )
    }
}

extension WebRTCCoordinator.StateMachine.Stage {

    /// Represents the migrated stage in the WebRTC coordinator state machine.
    final class MigratedStage:
        WebRTCCoordinator.StateMachine.Stage,
        @unchecked Sendable {
        private let disposableBag = DisposableBag()

        /// Initializes a new instance of `MigratedStage`.
        /// - Parameter context: The context for the migrated stage.
        init(
            _ context: Context
        ) {
            super.init(id: .migrated, context: context)
        }

        /// Performs the transition from a previous stage to this migrated stage.
        /// - Parameter previousStage: The stage from which the transition is
        ///   occurring.
        /// - Returns: This `MigratedStage` instance if the transition is valid,
        ///   otherwise `nil`.
        /// - Note: Valid transition from: `.migrating`
        override func transition(
            from previousStage: WebRTCCoordinator.StateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .migrating:
                execute()
                return self
            default:
                return nil
            }
        }

        /// Executes the migrated stage logic.
        private func execute() {
            Task(disposableBag: disposableBag) { [weak self] in
                guard let self else { return }

                do {
                    guard
                        let coordinator = context.coordinator
                    else {
                        throw ClientError(
                            "WebRTCCoordinator instance not available."
                        )
                    }

                    /// The coordinator join request for migration is still a
                    /// join-lifecycle stage and must be reported separately
                    /// from the later SFU `WSJoin` stage.
                    ///
                    /// Migration already created a new join attempt in
                    /// ``MigratingStage``; this event pair records the
                    /// coordinator REST join for that same attempt and marks it
                    /// with ``ClientEventJoinReason/migration``.
                    let coordinatorJoinDetails = ClientEventStageDetails(
                        coordinatorConnectId: context.coordinatorConnectId,
                        joinReason: .migration
                    )
                    let coordinatorJoinAttempt = await coordinator
                        .clientEventReporter
                        .beginStage(
                            .coordinatorJoin,
                            peerConnection: nil,
                            details: coordinatorJoinDetails
                        )
                    let sfuAdapter: SFUAdapter
                    let response: JoinCallResponse
                    do {
                        (sfuAdapter, response) = try await context
                            .authenticator
                            .authenticate(
                                coordinator: coordinator,
                                currentSFU: context.migratingFromSFU,
                                migratingFromList: context.migratingFromList,
                                create: false,
                                ring: false,
                                notify: false,
                                options: context.recoveryJoinOptions()
                            )
                    } catch {
                        // Authentication failed before assigning a new SFU, so
                        // resolve the migration CoordinatorJoin pair as failed.
                        await coordinator
                            .clientEventReporter
                            .completeStage(
                                coordinatorJoinAttempt,
                                retryCount: Int(context.reconnectAttempts),
                                details: coordinatorJoinDetails,
                                failure: .init(error)
                            )
                        throw error
                    }
                    // The coordinator returned a new session/SFU assignment.
                    // Attach the session id on completion because it may not be
                    // known when the initiated event is sent.
                    await coordinator
                        .clientEventReporter
                        .completeStage(
                            coordinatorJoinAttempt,
                            outcome: .success,
                            retryCount: Int(context.reconnectAttempts),
                            details: coordinatorJoinDetails.merging(
                                .init(
                                    callSessionId: response.call.session?.id
                                        ?? response.call.currentSessionId
                                )
                            ),
                            failure: nil
                        )

                    // Start observing SFU-full errors on the newly assigned SFU
                    // so chained migrations continue to work after this stage.
                    context.sfuFullObserver = .init(sfuAdapter)

                    /// We provide the ``SFUAdapter`` to the authenticator which will ensure
                    /// that we will continue only when the WS `connectionState` on the
                    /// ``SFUAdapter`` has changed to `.authenticating`.
                    try await context.authenticator.waitForAuthentication(on: sfuAdapter)

                    /// With the ``SFUAdapter`` having a `connectionState` to
                    /// `.authenticating`, we store the instance on the ``WebRTCStateAdapter``.
                    await coordinator.stateAdapter.set(sfuAdapter: sfuAdapter)
                    /// From the ``JoinCallResponse`` we got from the authenticator, we extract
                    /// the name of the SFU we are currently connected, so we can use it later on
                    /// during `migration`.
                    context.currentSFU = response.credentials.server.edgeName
                    log.debug(
                        "Migrating from \(context.migratingFromSFU) → \(context.currentSFU).",
                        subsystems: .webRTC
                    )

                    /// If there is an SFUAdapter from the previous session available, we create
                    /// an observer that will expect to receive the ``ParticipantMigrationComplete``
                    /// event (from the previous session's SFUAdapter).
                    /// If the event is received before the expiration of the deadline the migration will
                    /// be completed successfully. In any other case, the migration will fail and a
                    /// `.rejoin` will be triggered.
                    if let previousSFU = context.previousSFUAdapter {
                        context.migrationStatusObserver = .init(
                            migratingFrom: previousSFU
                        )
                    } else {
                        context.migrationStatusObserver = nil
                    }

                    transitionOrDisconnect(.joining(context))
                } catch {
                    transitionDisconnectOrError(error)
                }
            }
        }
    }
}
