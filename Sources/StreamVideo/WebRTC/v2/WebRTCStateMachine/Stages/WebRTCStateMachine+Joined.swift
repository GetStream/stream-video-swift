//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension WebRTCStateMachine.Stage {

    static func joined(
        _ coordinator: WebRTCCoordinator?,
        sfuAdapter: SFUAdapter,
        callSettings: CallSettings,
        videoOptions: VideoOptions,
        connectOptions: ConnectOptions,
        fastReconnectDeadlineSeconds: TimeInterval
    ) -> WebRTCStateMachine.Stage {
        JoinedStage(
            coordinator,
            sfuAdapter: sfuAdapter,
            callSettings: callSettings,
            videoOptions: videoOptions,
            connectOptions: connectOptions,
            fastReconnectDeadlineSeconds: fastReconnectDeadlineSeconds
        )
    }
}

extension WebRTCStateMachine.Stage {

    final class JoinedStage: WebRTCStateMachine.Stage {

        private let sfuAdapter: SFUAdapter
        private let callSettings: CallSettings
        private let videoOptions: VideoOptions
        private let connectOptions: ConnectOptions
        private let fastReconnectDeadlineSeconds: TimeInterval

        private let disposableBag = DisposableBag()

        init(
            _ coordinator: WebRTCCoordinator?,
            sfuAdapter: SFUAdapter,
            callSettings: CallSettings,
            videoOptions: VideoOptions,
            connectOptions: ConnectOptions,
            fastReconnectDeadlineSeconds: TimeInterval
        ) {
            self.sfuAdapter = sfuAdapter
            self.callSettings = callSettings
            self.videoOptions = videoOptions
            self.connectOptions = connectOptions
            self.fastReconnectDeadlineSeconds = fastReconnectDeadlineSeconds
            super.init(id: .joined, coordinator: coordinator)
        }

        override func transition(
            from previousStage: WebRTCStateMachine.Stage
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
                guard let coordinator else {
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
                
                // Setup user-media
                coordinator.localTracksAdapter.setupIfRequired(
                    callSettings: callSettings,
                    videoOptions: videoOptions,
                    connectOptions: connectOptions,
                    videoConfig: coordinator.videoConfig
                )

                do {
                    try coordinator.peerConnectionsAdapter.setupIfRequired(
                        connectionOfType: .publisher,
                        trackIdProvider: { [weak coordinator] _, trackType in
                            guard let localTracksAdapter = coordinator?.localTracksAdapter else {
                                return ""
                            }
                            switch trackType {
                            case .audio:
                                return localTracksAdapter.audioTrack?.trackId ?? ""
                            case .video:
                                return localTracksAdapter.videoTrack?.trackId ?? ""
                            case .screenShare:
                                return localTracksAdapter.screenShareTrack?.trackId ?? ""
                            default:
                                return ""
                            }
                        }
                    )
                } catch {
                    log.error(error)
                }
            }
        }

        private func observeConnection() {
            sfuAdapter
                .connectionSubject
                .compactMap {
                    switch $0 {
                    case let .disconnected(source):
                        return source
                    default:
                        return nil
                    }
                }
                .sink { [weak self] in
                    guard let self else { return }
                    do {
                        try transition?(
                            .disconnected(
                                coordinator,
                                sfuAdapter: sfuAdapter,
                                callSettings: callSettings,
                                videoOptions: videoOptions,
                                connectOptions: connectOptions,
                                disconnectionSource: $0,
                                reconnectionStrategy: reconnectionStrategyToUse()
                            )
                        )
                    } catch {
                        transitionErrorOrLog(error)
                    }
                }
                .store(in: disposableBag)
        }

        private func observeMigrationEvent() {
            sfuAdapter
                .eventSubject
                .compactMap {
                    switch $0 {
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
                .sink { [weak self] _ in
                    guard let self else { return }
                    do {
                        try transition?(
                            .migrating(
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
                .store(in: disposableBag)
        }

        private func observeDisconnectEvent() {
            sfuAdapter
                .eventSubject
                .compactMap {
                    switch $0 {
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
                .sink { [weak self] _ in
                    guard let self else { return }
                    do {
                        try transition?(
                            .leaving(coordinator, sfuAdapter: sfuAdapter)
                        )
                    } catch {
                        transitionErrorOrLog(error)
                    }
                }
                .store(in: disposableBag)
        }

        private func reconnectionStrategyToUse() -> ReconnectionStrategy {
            switch sfuAdapter.preferredReconnectionStrategy {
            case .fast:
                return .fast(
                    disconnectedSince: Date(),
                    deadline: fastReconnectDeadlineSeconds
                )

            case .clean:
                return .clean(
                    callSettings: callSettings,
                    videoOptions: videoOptions,
                    connectOptions: connectOptions
                )

            case .rejoin:
                return .rejoin(
                    callSettings: callSettings,
                    videoOptions: videoOptions,
                    connectOptions: connectOptions
                )

            case .migrate:
                return .migrate

            default:
                return .clean(
                    callSettings: callSettings,
                    videoOptions: videoOptions,
                    connectOptions: connectOptions
                )
            }
        }
    }
}

enum ReconnectionStrategy {
    case fast(disconnectedSince: Date, deadline: TimeInterval)
    case clean(
        callSettings: CallSettings,
        videoOptions: VideoOptions,
        connectOptions: ConnectOptions
    )
    case rejoin(
        callSettings: CallSettings,
        videoOptions: VideoOptions,
        connectOptions: ConnectOptions
    )
    case migrate
}
