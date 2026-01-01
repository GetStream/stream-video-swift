//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
import StreamWebRTC

extension RTCAudioStore {

    /// Bridges `RTCAudioSession` route updates into store state so downstream
    /// features can react to speaker/headset transitions.
    final class RouteChangeEffect: StoreEffect<RTCAudioStore.Namespace>, @unchecked Sendable {

        private let audioSessionObserver: RTCAudioSessionPublisher
        private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)
        private var disposableBag = DisposableBag()

        convenience init(_ source: RTCAudioSession) {
            self.init(.init(source))
        }

        init(_ audioSessionObserver: RTCAudioSessionPublisher) {
            self.audioSessionObserver = audioSessionObserver
            super.init()

            audioSessionObserver
                .publisher
                .compactMap {
                    switch $0 {
                    case let .didChangeRoute(reason, from, to):
                        return (
                            reason,
                            RTCAudioStore.StoreState.AudioRoute(from),
                            RTCAudioStore.StoreState.AudioRoute(to, reason: reason)
                        )
                    default:
                        return nil
                    }
                }
                .receive(on: processingQueue)
                .log(.debug, subsystems: .audioSession) { "AudioRoute updated \($1) → \($2) due to reason:\($0)." }
                .map { $0.2 }
                .sink { [weak self] in self?.dispatcher?.dispatch(.setCurrentRoute($0)) }
                .store(in: disposableBag)
        }
    }
}
