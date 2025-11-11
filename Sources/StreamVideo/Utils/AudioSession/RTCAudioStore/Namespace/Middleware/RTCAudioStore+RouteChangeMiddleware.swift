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
        private var pauseUntilSpeaker = false

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
            case .avAudioSession(.prepareForSpeakerTransition):
//                processingQueue.addOperation { [weak self] in
//                    self?.pauseUntilSpeaker = true
//                }
                break

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
            let currentRoute = StoreState.AudioRoute(to)
            let previousRoute = StoreState.AudioRoute(from)

            processingQueue.addOperation { [weak self] in
                guard let self else { return }

                if pauseUntilSpeaker, !currentRoute.isSpeaker {
                    log.debug(
                        "AudioSession route updated from \(previousRoute) → \(currentRoute) but we are waiting for speaker transition. Skipping.",
                        subsystems: .audioSession
                    )
                    return
                }

                let actions: [StoreActionBox<RTCAudioStore.StoreAction>] = [
                    .normal(.setCurrentRoute(currentRoute))
                ]

                pauseUntilSpeaker = false
                dispatcher?.dispatch(actions)
            }
        }
    }
}
