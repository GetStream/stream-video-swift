//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension WebRTCStateMachine.Stage {

    static func connected(
        _ coordinator: WebRTCCoordinator?,
        sfuAdapter: SFUAdapter,
        callSettings: CallSettings,
        videoOptions: VideoOptions,
        connectOptions: ConnectOptions
    ) -> WebRTCStateMachine.Stage {
        ConnectedStage(
            coordinator,
            sfuAdapter: sfuAdapter,
            callSettings: callSettings,
            videoOptions: videoOptions,
            connectOptions: connectOptions
        )
    }
}

extension WebRTCStateMachine.Stage {

    final class ConnectedStage: WebRTCStateMachine.Stage {

        private let sfuAdapter: SFUAdapter
        private let callSettings: CallSettings
        private let videoOptions: VideoOptions
        private let connectOptions: ConnectOptions

        init(
            _ coordinator: WebRTCCoordinator?,
            sfuAdapter: SFUAdapter,
            callSettings: CallSettings,
            videoOptions: VideoOptions,
            connectOptions: ConnectOptions
        ) {
            self.sfuAdapter = sfuAdapter
            self.callSettings = callSettings
            self.videoOptions = videoOptions
            self.connectOptions = connectOptions
            super.init(id: .connected, coordinator: coordinator)
        }

        override func transition(
            from previousStage: WebRTCStateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .connecting:
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
                        transitionErrorOrLog(error)
                    }
                }
                return self
            default:
                return nil
            }
        }
    }
}
