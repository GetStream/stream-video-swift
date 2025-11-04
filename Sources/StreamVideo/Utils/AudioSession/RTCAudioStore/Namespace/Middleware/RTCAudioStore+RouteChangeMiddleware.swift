//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
import StreamWebRTC

extension RTCAudioStore {

    /// Bridges `RTCAudioSession` route updates into store state so downstream
    /// features can react to speaker/headset transitions.
    final class RouteChangeMiddleware: Middleware<RTCAudioStore.Namespace>, @unchecked Sendable {

        private let audioSessionObserver: RTCAudioSessionPublisher
        private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)
        private let disposableBag = DisposableBag()
        private var ignoreRouteChanges = false

        convenience init(_ source: RTCAudioSession) {
            self.init(.init(source))
        }

        init(_ audioSessionObserver: RTCAudioSessionPublisher) {
            self.audioSessionObserver = audioSessionObserver
            super.init()

            audioSessionObserver
                .publisher
                .compactMap {
                    guard
                        case let .didChangeRoute(reason, from, to) = $0
                    else {
                        return nil
                    }
                    return (reason, from, to)
                }
                .receive(on: processingQueue)
                .sink { [weak self] in self?.didChangeRoute(reason: $0, from: $1, to: $2) }
                .store(in: disposableBag)
        }

        override func apply(
            state: RTCAudioStore.StoreState,
            action: RTCAudioStore.StoreAction,
            file: StaticString,
            function: StaticString,
            line: UInt
        ) {
            switch action {
            case let .setRouteTransitionState(value):
                processingQueue.addOperation { [weak self] in
                    self?.ignoreRouteChanges = value == .updating
                }
            default:
                break
            }
        }

        // MARK: - Private Helpers
        
        /// Handles route changes by persisting the new route and adapting the
        /// output port override.
        private func didChangeRoute(
            reason: AVAudioSession.RouteChangeReason,
            from: AVAudioSessionRouteDescription,
            to: AVAudioSessionRouteDescription
        ) {
            let currentRoute = StoreState.AudioRoute(to, reason: reason)
            let previousRoute = StoreState.AudioRoute(from)

            if currentRoute.isSpeaker {
                dispatcher?.dispatch(.setSpeakerOutputChannels(currentRoute.outputs.first?.channels ?? 1))
            } else if currentRoute.isReceiver {
                dispatcher?.dispatch(.setReceiverOutputChannels(currentRoute.outputs.first?.channels ?? 1))
            }

            guard
                !ignoreRouteChanges
            else {
                log.debug(
                    "AudioSession route changed from \(previousRoute) to \(currentRoute) due to:\(reason) but the store identifier:io.getstream.audio.store is transitioning routes. Ignoring.",
                    subsystems: .audioSession
                )
                return
            }

            dispatcher?.dispatch([
                .normal(.setCurrentRoute(currentRoute)),
                .normal(.avAudioSession(.setOverrideOutputAudioPort(currentRoute.isSpeaker ? .speaker : .none)))
            ])
            log.debug(
                "AudioSession route changed from \(previousRoute) to \(currentRoute) due to:\(reason)",
                subsystems: .audioSession
            )
        }
    }
}
