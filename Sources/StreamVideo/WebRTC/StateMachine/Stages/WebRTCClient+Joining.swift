//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension WebRTCClient.StateMachine.Stage {

    static func joining(
        _ context: Context
    ) -> WebRTCClient.StateMachine.Stage {
        JoiningStage(
            context
        )
    }
}

extension WebRTCClient.StateMachine.Stage {

    final class JoiningStage: WebRTCClient.StateMachine.Stage {

        init(
            _ context: Context
        ) {
            super.init(id: .joining, context: context)
        }

        override func transition(
            from previousStage: WebRTCClient.StateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .connected:
                execute(isFastReconnecting: false)
                return self
            case .fastReconnected:
                execute(isFastReconnecting: true)
                return self
            case .migrated:
                executeMigration()
                return self
            default:
                return nil
            }
        }

        private func execute(
            isFastReconnecting: Bool
        ) {
            Task { [weak self] in
                guard let self else { return }

                do {
                    guard
                        let client = context.client
                    else {
                        throw ClientError(
                            "WebRCTAdapter instance not available."
                        )
                    }

                    let subscriberSessionDescription: String
                    if isFastReconnecting, let subscriber = client.subscriber {
                        let offer = try await subscriber.createOffer()
                        subscriberSessionDescription = offer.sdp
                    } else {
                        subscriberSessionDescription = try await client.tempOfferSdp()
                    }

                    await join(
                        client,
                        subscriberSessionDescription: subscriberSessionDescription,
                        isFastReconnecting: isFastReconnecting,
                        isMigrating: false,
                        sfuAdapter: client.sfuAdapter
                    )

                    let joinResponse = try await client
                        .sfuAdapter
                        .eventSubject
                        .compactMap {
                            if case let .sfuEvent(sfuEvent) = $0 {
                                return sfuEvent
                            } else {
                                return nil
                            }
                        }
                        .compactMap { (event: Stream_Video_Sfu_Event_SfuEvent.OneOf_EventPayload) in
                            if case let .joinResponse(response) = event {
                                return response
                            } else {
                                return nil
                            }
                        }
                        .nextValue(timeout: 5)

                    var context = context
                    context.fastReconnectDeadlineSeconds = TimeInterval(joinResponse.fastReconnectDeadlineSeconds)

                    if isFastReconnecting {
                        client.publisher?.restartIce()
                        client.subscriber?.restartIce()
                        client.sfuAdapter.sendHealthCheck()
                    } else {
                        client.sfuAdapter.sendHealthCheck()

                        _ = try await client
                            .sfuAdapter
                            .$connectionState
                            .filter {
                                switch $0 {
                                case .connected:
                                    return true
                                default:
                                    return false
                                }
                            }
                            .nextValue(timeout: 5)

                        if
                            let connectOptions = context.connectOptions,
                            let callSettings = context.callSettings
                        {
                            await client.setupUserMedia(
                                callSettings: callSettings
                            )

                            try await client._setupPeerConnections(
                                connectOptions: connectOptions,
                                videoOptions: client.videoOptions
                            )

                            try await client._publishLocalTracks(
                                connectOptions: connectOptions,
                                callSettings: callSettings
                            )
                        } else {
                            try transition?(.disconnected(context))
                        }
                    }

                    try transition?(
                        .joined(
                            context
                        )
                    )
                } catch {
                    do {
                        var context = self.context
                        context.disconnectionSource = .serverInitiated(
                            error: .init(error.localizedDescription)
                        )
                        try transition?(.disconnected(context))
                    } catch {
                        transitionErrorOrLog(error)
                    }
                }
            }
        }

        private func executeMigration() {
            Task { [weak self] in
                guard let self else { return }

                do {
                    guard
                        let client = context.client,
                        let migratingSFUAdapter = client.migratingSFUAdapter
                    else {
                        throw ClientError(
                            "WebRCTAdapter instance not available."
                        )
                    }

                    let subscriberSessionDescription = try await client.tempOfferSdp()
                    await join(
                        client,
                        subscriberSessionDescription: subscriberSessionDescription,
                        isFastReconnecting: false,
                        isMigrating: true,
                        sfuAdapter: migratingSFUAdapter
                    )

                    let joinResponse = try await migratingSFUAdapter
                        .eventSubject
                        .compactMap {
                            if case let .sfuEvent(sfuEvent) = $0 {
                                return sfuEvent
                            } else {
                                return nil
                            }
                        }
                        .compactMap { (event: Stream_Video_Sfu_Event_SfuEvent.OneOf_EventPayload) in
                            if case let .joinResponse(response) = event {
                                return response
                            } else {
                                return nil
                            }
                        }
                        .nextValue(timeout: 15)
                    migratingSFUAdapter.sendHealthCheck()

                    var context = context
                    context.fastReconnectDeadlineSeconds = TimeInterval(joinResponse.fastReconnectDeadlineSeconds)

                    await client.completeMigration()

                    try transition?(
                        .joined(
                            context
                        )
                    )
                } catch {
                    do {
                        context.disconnectionSource = .serverInitiated(
                            error: .init(error.localizedDescription)
                        )
                        try transition?(.disconnected(context))
                    } catch {
                        transitionErrorOrLog(error)
                    }
                }
            }
        }

        private func join(
            _ client: WebRTCClient,
            subscriberSessionDescription: String,
            isFastReconnecting: Bool,
            isMigrating: Bool,
            sfuAdapter: SFUAdapter
        ) async {
            let payload = await client.makeJoinRequest(
                subscriberSdp: subscriberSessionDescription,
                migrating: isMigrating,
                fastReconnect: isFastReconnecting
            )
            var event = Stream_Video_Sfu_Event_SfuRequest()
            event.requestPayload = .joinRequest(payload)

            sfuAdapter.send(message: event)
        }
    }
}
