//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension WebRTCStateMachine.Stage {

    static func migrated(
        _ coordinator: WebRTCCoordinator?,
        fromSFUAdapter: SFUAdapter,
        toSFUAdapter: SFUAdapter,
        callSettings: CallSettings,
        videoOptions: VideoOptions,
        connectOptions: ConnectOptions
    ) -> WebRTCStateMachine.Stage {
        MigratedStage(
            coordinator,
            fromSFUAdapter: fromSFUAdapter,
            toSFUAdapter: toSFUAdapter,
            callSettings: callSettings,
            videoOptions: videoOptions,
            connectOptions: connectOptions
        )
    }
}

extension WebRTCStateMachine.Stage {

    final class MigratedStage: WebRTCStateMachine.Stage {

        let fromSFUAdapter: SFUAdapter
        private let toSFUAdapter: SFUAdapter
        private let callSettings: CallSettings
        private let videoOptions: VideoOptions
        private let connectOptions: ConnectOptions

        init(
            _ coordinator: WebRTCCoordinator?,
            fromSFUAdapter: SFUAdapter,
            toSFUAdapter: SFUAdapter,
            callSettings: CallSettings,
            videoOptions: VideoOptions,
            connectOptions: ConnectOptions
        ) {
            self.fromSFUAdapter = fromSFUAdapter
            self.toSFUAdapter = toSFUAdapter
            self.callSettings = callSettings
            self.videoOptions = videoOptions
            self.connectOptions = connectOptions
            super.init(id: .migrated, coordinator: coordinator)
        }

        override func transition(
            from previousStage: WebRTCStateMachine.Stage
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
            Task {
                guard let coordinator else {
                    transitionErrorOrLog(
                        ClientError(
                            "WebRCTAdapter instance not available."
                        )
                    )
                    return
                }

                toSFUAdapter.connect()

                do {
                    _ = try await toSFUAdapter
                        .connectionSubject
                        .filter {
                            switch $0 {
                            case .authenticating:
                                return true
                            default:
                                return false
                            }
                        }
                        .nextValue(timeout: 10)

                    try transition?(
                        .joining(
                            coordinator,
                            sfuAdapter: toSFUAdapter,
                            callSettings: callSettings,
                            videoOptions: videoOptions,
                            connectOptions: connectOptions
                        )
                    )
                } catch {
                    transitionErrorOrLog(error)
                }
            }
        }
    }
}
