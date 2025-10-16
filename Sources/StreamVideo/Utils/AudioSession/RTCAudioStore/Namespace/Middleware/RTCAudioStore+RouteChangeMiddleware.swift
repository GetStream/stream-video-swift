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
        private let disposableBag = DisposableBag()

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
                .sink { [weak self] in self?.didChangeRoute(reason: $0, from: $1, to: $2) }
                .store(in: disposableBag)
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
