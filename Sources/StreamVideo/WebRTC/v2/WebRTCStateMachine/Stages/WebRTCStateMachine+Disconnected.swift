//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension WebRTCStateMachine.Stage {

    static func disconnected(
        _ coordinator: WebRTCCoordinator?,
        sfuAdapter: SFUAdapter,
        callSettings: CallSettings,
        videoOptions: VideoOptions,
        connectOptions: ConnectOptions,
        disconnectionSource: WebSocketConnectionState.DisconnectionSource,
        reconnectionStrategy: ReconnectionStrategy
    ) -> WebRTCStateMachine.Stage {
        DisconnectedStage(
            coordinator,
            sfuAdapter: sfuAdapter,
            callSettings: callSettings,
            videoOptions: videoOptions,
            connectOptions: connectOptions,
            disconnectionSource: disconnectionSource,
            reconnectionStrategy: reconnectionStrategy
        )
    }
}

extension WebRTCStateMachine.Stage {

    final class DisconnectedStage: WebRTCStateMachine.Stage {

        @Injected(\.internetConnectionObserver) private var internetConnectionObserver

        private let sfuAdapter: SFUAdapter
        private let callSettings: CallSettings
        private let videoOptions: VideoOptions
        private let connectOptions: ConnectOptions
        private let disconnectionSource: WebSocketConnectionState.DisconnectionSource
        private let reconnectionStrategy: ReconnectionStrategy

        private var internetObservationCancellable: AnyCancellable?

        init(
            _ coordinator: WebRTCCoordinator?,
            sfuAdapter: SFUAdapter,
            callSettings: CallSettings,
            videoOptions: VideoOptions,
            connectOptions: ConnectOptions,
            disconnectionSource: WebSocketConnectionState.DisconnectionSource,
            reconnectionStrategy: ReconnectionStrategy
        ) {
            self.sfuAdapter = sfuAdapter
            self.callSettings = callSettings
            self.videoOptions = videoOptions
            self.connectOptions = connectOptions
            self.disconnectionSource = disconnectionSource
            self.reconnectionStrategy = reconnectionStrategy
            super.init(id: .disconnected, coordinator: coordinator)
        }

        override func transition(
            from previousStage: WebRTCStateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .joined:
                Task {
                    // We need the task to ensure any transition will happen after
                    // this one has completed.
                    execute()
                }
                return self
            default:
                return nil
            }
        }

        private func execute() {
            guard
                case .available = internetConnectionObserver.status
            else {
                observeInternetConnection()
                return
            }

            reconnect()
        }

        private func reconnect() {
            do {
                switch reconnectionStrategy {
                case let .fast(disconnectedSince, deadline) where disconnectedSince.timeIntervalSinceNow <= deadline:
                    try transition?(
                        .fastReconnecting(
                            coordinator,
                            sfuAdapter: sfuAdapter,
                            callSettings: callSettings,
                            videoOptions: videoOptions,
                            connectOptions: connectOptions,
                            disconnectionSource: disconnectionSource,
                            reconnectionStrategy: reconnectionStrategy
                        )
                    )
                case .fast:
                    try transition?(
                        .cleanReconnecting(
                            coordinator,
                            callSettings: callSettings,
                            videoOptions: videoOptions,
                            connectOptions: connectOptions,
                            disconnectionSource: disconnectionSource,
                            reconnectionStrategy: .clean(
                                callSettings: callSettings,
                                videoOptions: videoOptions,
                                connectOptions: connectOptions
                            )
                        )
                    )
                case let .clean(callSettings, videoOptions, connectOptions):
                    try transition?(
                        .cleanReconnecting(
                            coordinator,
                            callSettings: callSettings,
                            videoOptions: videoOptions,
                            connectOptions: connectOptions,
                            disconnectionSource: disconnectionSource,
                            reconnectionStrategy: .clean(
                                callSettings: callSettings,
                                videoOptions: videoOptions,
                                connectOptions: connectOptions
                            )
                        )
                    )
                case let .rejoin(callSettings, videoOptions, connectOptions):
                    try transition?(
                        .rejoining(
                            coordinator,
                            sfuAdapter: sfuAdapter,
                            callSettings: callSettings,
                            videoOptions: videoOptions,
                            connectOptions: connectOptions,
                            disconnectionSource: disconnectionSource,
                            reconnectionStrategy: reconnectionStrategy
                        )
                    )
                case .migrate:
                    break
                }
            } catch {
                transitionErrorOrLog(error)
            }
        }

        private func observeInternetConnection() {
            internetObservationCancellable?.cancel()
            internetObservationCancellable = internetConnectionObserver
                .publisher
                .filter { $0.isAvailable }
                .sink { [weak self] _ in self?.execute() }
        }
    }
}
