//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension WebRTCCoordinator.StateMachine.Stage {

    static func migrated(
        _ context: Context
    ) -> WebRTCCoordinator.StateMachine.Stage {
        MigratedStage(
            context
        )
    }
}

extension WebRTCCoordinator.StateMachine.Stage {

    final class MigratedStage: WebRTCCoordinator.StateMachine.Stage {

        init(
            _ context: Context
        ) {
            super.init(id: .migrated, context: context)
        }

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

        private func execute() {
            Task { [weak self] in
                guard let self else { return }

                do {
                    guard
                        let coordinator = context.coordinator
                    else {
                        throw ClientError(
                            "WebRCTAdapter instance not available."
                        )
                    }

                    let authenticator = Authenticator()
                    let (sfuAdapter, response) = try await authenticator
                        .authenticate(
                            coordinator: coordinator,
                            currentSFU: context.currentSFU,
                            create: false,
                            ring: false
                        )

                    try await authenticator.connect(sfuAdapter: sfuAdapter)

                    await coordinator.stateAdapter.set(sfuAdapter: sfuAdapter)
                    context.currentSFU = response.credentials.server.edgeName

                    if let previousSFU = context.previousSFUAdapter {
                        context.migrationStatusObserver = .init(
                            migratingFrom: previousSFU
                        )
                    }

                    try transition?(
                        .joining(
                            context
                        )
                    )
                } catch {
                    transitionErrorOrLog(error)
                }
            }
        }
    }
}
