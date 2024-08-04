//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension WebRTCClient.StateMachine.Stage {

    static func joined(
        _ context: Context
    ) -> WebRTCClient.StateMachine.Stage {
        JoinedStage(
            context
        )
    }
}

extension WebRTCClient.StateMachine.Stage {

    final class JoinedStage: WebRTCClient.StateMachine.Stage {

        private let disposableBag = DisposableBag()

        init(
            _ context: Context
        ) {
            super.init(id: .joined, context: context)
        }

        override func transition(
            from previousStage: WebRTCClient.StateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .joining:
                execute()
                return self
            default:
                return nil
            }
        }

        private func execute() {
            Task {
                guard let coordinator = context.client else {
                    transitionErrorOrLog(
                        ClientError(
                            "WebRCTAdapter instance not available."
                        )
                    )
                    return
                }

                observeConnection()
                observeMigrationEvent()
                observeDisconnectEvent()
                observePreferredReconnectionStrategy()

                context.webSocketClient.engine?.send(
                    message: Stream_Video_Sfu_Event_HealthCheckRequest()
                )

                // Setup user-media
//                coordinator.localTracksAdapter.setupIfRequired(
//                    callSettings: callSettings,
//                    videoOptions: videoOptions,
//                    connectOptions: connectOptions,
//                    videoConfig: coordinator.videoConfig
//                )
                await coordinator.setupUserMedia(
                    callSettings: context.callSettings
                )

                try await coordinator._setupPeerConnections(
                    connectOptions: context.connectOptions,
                    videoOptions: coordinator.videoOptions
                )

//                coordinator._sendHealthCheck(on: context.webSocketClient)
                context.client?.sfuAdapter.sendHealthCheck()

                try await coordinator._publishLocalTracks(
                    connectOptions: context.connectOptions,
                    callSettings: context.callSettings
                )
            }
        }

        private func observeConnection() {
            context
                .webSocketClient
                .connectionSubject
                .compactMap {
                    switch $0 {
                    case let .disconnected(source):
                        return source
                    default:
                        return nil
                    }
                }
                .sink { [weak self] (source: WebSocketConnectionState.DisconnectionSource) in
                    guard let self else { return }
                    do {
                        try transition?(
                            .disconnected(
                                context
                            )
                        )
                    } catch {
                        transitionErrorOrLog(error)
                    }
                }
                .store(in: disposableBag)
        }

        private func observeMigrationEvent() {
            context
                .webSocketClient
                .eventSubject
                .compactMap {
                    if case let .sfuEvent(sfuEvent) = $0 {
                        return sfuEvent
                    } else {
                        return nil
                    }
                }
                .compactMap { (event: Stream_Video_Sfu_Event_SfuEvent.OneOf_EventPayload) in
                    switch event {
                    case let .error(error):
                        if error.reconnectStrategy == .migrate {
                            return true
                        } else {
                            return nil
                        }
                    default:
                        return nil
                    }
                }
                .sink { [weak self] (_: Bool) in
                    guard let self else { return }
                    do {
//                        try transition?(
//                            .migrating(
//                                coordinator,
//                                sfuAdapter: sfuAdapter,
//                                callSettings: callSettings,
//                                videoOptions: videoOptions,
//                                connectOptions: connectOptions
//                            )
//                        )
                    } catch {
                        transitionErrorOrLog(error)
                    }
                }
                .store(in: disposableBag)
        }

        private func observeDisconnectEvent() {
            context
                .webSocketClient
                .eventSubject
                .compactMap {
                    if case let .sfuEvent(sfuEvent) = $0 {
                        return sfuEvent
                    } else {
                        return nil
                    }
                }
                .compactMap { (event: Stream_Video_Sfu_Event_SfuEvent.OneOf_EventPayload) in
                    switch event {
                    case let .error(error):
                        if error.reconnectStrategy == .disconnect {
                            return true
                        } else {
                            return nil
                        }
                    default:
                        return nil
                    }
                }
                .sink { [weak self] (_: Bool) in
                    guard let self else { return }
                    do {
                        try transition?(
                            .leaving(context)
                        )
                    } catch {
                        transitionErrorOrLog(error)
                    }
                }
                .store(in: disposableBag)
        }

        private func observePreferredReconnectionStrategy() {
            context
                .webSocketClient
                .eventSubject
                .compactMap {
                    if case let .sfuEvent(sfuEvent) = $0 {
                        return sfuEvent
                    } else {
                        return nil
                    }
                }
                .compactMap { (event: Stream_Video_Sfu_Event_SfuEvent.OneOf_EventPayload) in
                    switch event {
                    case let .error(error):
                        return error.reconnectStrategy
                    default:
                        return nil
                    }
                }
                .compactMap { [weak self] in self?.reconnectionStrategyToUse($0) }
                .sink { [weak self] in self?.context.reconnectionStrategy = $0 }
                .store(in: disposableBag)
        }

        private func reconnectionStrategyToUse(
            _ reconnectionStrategy: Stream_Video_Sfu_Models_WebsocketReconnectStrategy
        ) -> ReconnectionStrategy {
            switch reconnectionStrategy {
            case .fast:
                return .fast(
                    disconnectedSince: Date(),
                    deadline: context.fastReconnectDeadlineSeconds
                )

            case .clean:
                return .clean(
                    callSettings: context.callSettings,
                    videoOptions: context.videoOptions,
                    connectOptions: context.connectOptions
                )

            case .rejoin:
                return .rejoin(
                    callSettings: context.callSettings,
                    videoOptions: context.videoOptions,
                    connectOptions: context.connectOptions
                )

            case .migrate:
                return .migrate

            default:
                return .clean(
                    callSettings: context.callSettings,
                    videoOptions: context.videoOptions,
                    connectOptions: context.connectOptions
                )
            }
        }
    }
}
