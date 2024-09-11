//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension WebRTCCoordinator.StateMachine.Stage {

    static func connecting(
        _ context: Context,
        ring: Bool
    ) -> WebRTCCoordinator.StateMachine.Stage {
        ConnectingStage(
            context,
            ring: ring
        )
    }
}

extension WebRTCCoordinator.StateMachine.Stage {

    final class ConnectingStage: WebRTCCoordinator.StateMachine.Stage {

        private let ring: Bool

        init(
            _ context: Context,
            ring: Bool
        ) {
            self.ring = ring
            super.init(id: .connecting, context: context)
        }

        override func transition(
            from previousStage: WebRTCCoordinator.StateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .idle:
                execute(create: true, updateSession: false)
                return self
            case .rejoining:
                execute(create: false, updateSession: true)
                return self
            default:
                return nil
            }
        }

        private func execute(create: Bool, updateSession: Bool) {
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

                    if updateSession {
                        await coordinator.stateAdapter.refreshSession()
                    }

                    let authenticator = Authenticator()
                    let (sfuAdapter, response) = try await authenticator
                        .authenticate(
                            coordinator: coordinator,
                            currentSFU: nil,
                            create: create,
                            ring: ring
                        )

                    try await authenticator.connect(sfuAdapter: sfuAdapter)

                    await coordinator.stateAdapter.set(sfuAdapter: sfuAdapter)
                    context.currentSFU = response.credentials.server.edgeName

                    transitionOrDisconnect(.connected(context))
                } catch {
                    transitionDisconnectOrError(error)
                }
            }
        }
    }
}
