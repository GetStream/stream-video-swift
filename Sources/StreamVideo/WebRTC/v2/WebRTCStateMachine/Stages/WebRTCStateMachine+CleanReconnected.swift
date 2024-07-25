//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension WebRTCStateMachine.Stage {

    static func cleanReconnected(
        _ coordinator: WebRTCCoordinator?,
        sfuAdapter: SFUAdapter,
        callSettings: CallSettings,
        videoOptions: VideoOptions,
        connectOptions: ConnectOptions,
        disconnectionSource: WebSocketConnectionState.DisconnectionSource,
        reconnectionStrategy: ReconnectionStrategy
    ) -> WebRTCStateMachine.Stage {
        CleanReconnectedStage(
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

    final class CleanReconnectedStage: WebRTCStateMachine.Stage {

        private let sfuAdapter: SFUAdapter
        private let callSettings: CallSettings
        private let videoOptions: VideoOptions
        private let connectOptions: ConnectOptions
        private let disconnectionSource: WebSocketConnectionState.DisconnectionSource
        private let reconnectionStrategy: ReconnectionStrategy

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
            super.init(id: .cleanReconnected, coordinator: coordinator)
        }

        override func transition(
            from previousStage: WebRTCStateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .cleanReconnecting:
                Task {
                    do {
                        try transition?(
                            .joining(
                                coordinator,
                                sfuAdapter: sfuAdapter,
                                callSettings: callSettings,
                                videoOptions: videoOptions,
                                connectOptions: connectOptions
                            )
                        )
                    } catch {
                        log.error(error)
                    }
                }
                return self
            default:
                return nil
            }
        }
    }
}
