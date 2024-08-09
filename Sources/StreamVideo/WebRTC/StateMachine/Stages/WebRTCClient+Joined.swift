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

        @Injected(\.internetConnectionObserver) private var internetConnectionObserver

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
            Task { [weak self] in
                guard let self else { return }
                do {
                    guard
                        context.client != nil
                    else {
                        throw ClientError(
                            "WebRCTAdapter instance not available."
                        )
                    }

                    observeConnection()
                    observeMigrationEvent()
                    observeDisconnectEvent()
                    observePreferredReconnectionStrategy()
                    observeInternetConnection()
                } catch {
                    transitionErrorOrLog(error)
                }
            }
        }

        private func observeConnection() {
            context
                .client?.sfuAdapter
                .$connectionState
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
                    context.disconnectionSource = source
                    if let sfuError = (source.serverError?.underlyingError as? Stream_Video_Sfu_Models_Error) {
                        context.reconnectionStrategy = sfuError.shouldRetry
                        ? .fast(
                            disconnectedSince: .init(),
                            deadline: context.fastReconnectDeadlineSeconds
                        )
                        : .rejoin
                    }

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
                .client?
                .sfuAdapter
                .publisher(eventType: Stream_Video_Sfu_Event_Error.self)
                .filter { $0.reconnectStrategy == .migrate }
                .sink { [weak self] _ in
                    guard let self else { return }
                    do {
                        try transition?(.migrating(context))
                    } catch {
                        transitionErrorOrLog(error)
                    }
                }
                .store(in: disposableBag)
        }

        private func observeDisconnectEvent() {
            context
                .client?
                .sfuAdapter
                .publisher(eventType: Stream_Video_Sfu_Event_Error.self)
                .filter { $0.reconnectStrategy == .disconnect }
                .sink { [weak self] _ in
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
                .client?
                .sfuAdapter
                .publisher(eventType: Stream_Video_Sfu_Event_Error.self)
                .map { $0.reconnectStrategy }
                .compactMap { [weak self] in self?.reconnectionStrategyToUse($0) }
                .log(.debug, subsystems: .webRTC) { "Reconnection strategy updated to \($0)." }
                .sink { [weak self] in self?.context.reconnectionStrategy = $0 }
                .store(in: disposableBag)
        }

        private func observeInternetConnection() {
            internetConnectionObserver
                .$status
                .receive(on: DispatchQueue.main)
                .filter { $0 != .unknown }
                .log(.debug, subsystems: .webRTC) { "Internet connection status updated to \($0)" }
                .filter { !$0.isAvailable }
                .removeDuplicates()
                .sink { [weak self] _ in
                    guard let self else { return }
                    do {
                        context.reconnectionStrategy = .fast(
                            disconnectedSince: .init(),
                            deadline: context.fastReconnectDeadlineSeconds
                        )
                        context.disconnectionSource = .serverInitiated(error: .NetworkError("Not available"))
                        try transition?(
                            .disconnected(context)
                        )
                    } catch {
                        transitionErrorOrLog(error)
                    }
                }
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

            case .rejoin:
                return .rejoin

            case .migrate:
                return .migrate

            case .disconnect:
                return .disconnected

            default:
                return .rejoin
            }
        }
    }
}
