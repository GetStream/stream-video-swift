//
//  WebRTCCoordinator+Connecting.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 7/8/24.
//

import Foundation

extension WebRTCCoordinator.StateMachine.Stage {

    static func connecting(
        _ context: Context
    ) -> WebRTCCoordinator.StateMachine.Stage {
        ConnectingStage(
            context
        )
    }
}

extension WebRTCCoordinator.StateMachine.Stage {

    final class ConnectingStage: WebRTCCoordinator.StateMachine.Stage {

        init(
            _ context: Context
        ) {
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
                            create: create
                        )

                    try await coordinator.stateAdapter
                        .didUpdate(sfuAdapter: sfuAdapter)
                    context.currentSFU = response.credentials.server.edgeName

                    try await authenticator.connect(sfuAdapter: sfuAdapter)

                    try transition?(
                        .connected(
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

