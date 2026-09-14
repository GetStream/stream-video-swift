//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
import StreamWebRTC

extension RTCAudioStore {

    /// Bridges `RTCAudioSession` route updates into store state and restores
    /// SDK-owned route policy after a media-services reset.
    ///
    /// iOS emits the reset callback after its media-services process restarts.
    /// The call can remain connected while its previously selected output route
    /// is no longer applied, leaving playback on an unexpected output.
    ///
    /// WebRTC restores its audio-session configuration and engine. This effect
    /// restores the output-port override maintained by `RTCAudioStore`, which
    /// is not part of `RTCAudioSessionConfiguration`.
    final class RouteChangeEffect: StoreEffect<RTCAudioStore.Namespace>, @unchecked Sendable {

        private let audioSessionObserver: RTCAudioSessionPublisher
        private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)
        private var disposableBag = DisposableBag()

        convenience init(_ source: RTCAudioSession) {
            self.init(.init(source))
        }

        /// Starts observing route changes and media-services resets.
        ///
        /// Reset recovery uses a dedicated action because the cached route can
        /// remain unchanged even though iOS discarded the live output override.
        /// - Parameter audioSessionObserver: The publisher that bridges WebRTC
        ///   audio-session delegate callbacks.
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

            audioSessionObserver
                .publisher
                .filter {
                    if case .mediaServicesWereReset = $0 {
                        return true
                    }
                    return false
                }
                .receive(on: processingQueue)
                .sink { [weak self] _ in
                    self?.dispatcher?.dispatch(
                        .avAudioSession(.restoreOutputAudioPortAfterMediaServicesReset)
                    )
                }
                .store(in: disposableBag)
        }
    }
}
