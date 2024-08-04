//
//  WebRTC+Connecting.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 1/8/24.
//

import Foundation

extension WebRTCClient.StateMachine.Stage {

    static func connecting(
        _ context: Context
    ) -> WebRTCClient.StateMachine.Stage {
        ConnectingStage(
            context
        )
    }
}

extension WebRTCClient.StateMachine.Stage {

    final class ConnectingStage: WebRTCClient.StateMachine.Stage {

        init(
            _ context: Context
        ) {
            super.init(id: .connecting, context: context)
        }

        override func transition(
            from previousStage: WebRTCClient.StateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .idle:
                execute()
                return self
            case .rejoining:
                execute()
                return self
            default:
                return nil
            }
        }

        private func execute() {
            Task {
                guard
                    let client = context.client
                else {
                    transitionErrorOrLog(
                        ClientError(
                            "WebRCTAdapter instance not available."
                        )
                    )
                    return
                }

                do {
                    let response = try await client
                        .callAuthenticator
                        .authenticate()

                    client.prepare(
                        .connect(
                            url: response.credentials.server.url,
                            token: response.credentials.token,
                            webSocketURL: response.credentials.server.wsEndpoint,
                            ownCapabilities: response.ownCapabilities,
                            audioSettings: response.call.settings.audio
                        )
                    )

                    await client.setupUserMedia(callSettings: context.callSettings)
                    client.sfuAdapter.connect()

                    _ = try await client
                        .sfuAdapter
                        .$connectionState
                        .filter {
                            switch $0 {
                            case .authenticating:
                                return true
                            default:
                                return false
                            }
                        }
                        .nextValue(timeout: 10)

//                    try transition?(
//                        .connected(
//                            context
//                        )
//                    )
                } catch {
                    transitionErrorOrLog(error)
                }
            }
        }
    }
}

