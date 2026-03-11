//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

extension Call_IntegrationTests.Helpers {
    final class StreamVideoHelper: @unchecked Sendable {
        static let videoConfig: VideoConfig = .dummy()
        enum ConnectMode { case none, onInit, afterInit }
        enum ClientRegisterMode { case none, auto, autoWithouSingletonUpdate }
        enum ClientResolutionMode { case `default`, ignoreCache }

        let videoConfig: VideoConfig
        let pushNotificationConfig: PushNotificationsConfig

        private var registeredClients: [String: StreamVideo] = [:]

        init(
            videoConfig: VideoConfig = StreamVideoHelper.videoConfig,
            pushNotificationConfig: PushNotificationsConfig = .default
        ) {
            self.videoConfig = videoConfig
            self.pushNotificationConfig = pushNotificationConfig
        }

        func dismantle() async {
            for client in registeredClients.values {
                await client.disconnect()
            }

            StreamVideoProviderKey.currentValue = nil

            registeredClients = [:]
        }

        func buildClient(
            apiKey: String,
            token: String,
            userId: String,
            connectMode: ConnectMode,
            clientResolutionMode: ClientResolutionMode,
            clientRegisterMode: ClientRegisterMode
        ) async throws -> StreamVideo {
            let autoConnectOnInit = {
                switch connectMode {
                case .none:
                    return false
                case .onInit:
                    return true
                case .afterInit:
                    return false
                }
            }()

            let currentStreamVideo = StreamVideoProviderKey.currentValue
            let result = {
                if clientResolutionMode == .default, let existingClient = registeredClients[userId] {
                    return existingClient
                } else {
                    return StreamVideo(
                        apiKey: apiKey,
                        user: User(id: userId),
                        token: .init(rawValue: token),
                        videoConfig: videoConfig,
                        pushNotificationsConfig: pushNotificationConfig,
                        tokenProvider: { _ in },
                        autoConnectOnInit: autoConnectOnInit
                    )
                }
            }()

            if connectMode == .afterInit {
                try await result.connect()
            }

            switch clientRegisterMode {
            case .none:
                // Reassign the StreamVideo that was assigned before the
                // new instance gets created.
                StreamVideoProviderKey.currentValue = currentStreamVideo

            case .auto:
                StreamVideoProviderKey.currentValue = result
                registeredClients[userId] = result

            case .autoWithouSingletonUpdate:
                // Reassign the StreamVideo that was assigned before the
                // new instance gets created.
                StreamVideoProviderKey.currentValue = currentStreamVideo
                registeredClients[userId] = result
            }

            return result
        }

        func removeClient(
            for userId: String,
            disconnect: Bool
        ) async {
            guard let client = registeredClients[userId] else {
                return
            }

            if disconnect {
                await client.disconnect()
            }

            registeredClients[userId] = nil
        }
    }
}
