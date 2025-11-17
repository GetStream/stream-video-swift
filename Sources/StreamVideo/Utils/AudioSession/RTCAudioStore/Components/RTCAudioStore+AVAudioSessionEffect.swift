//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
import StreamWebRTC

extension RTCAudioStore {

    /// Bridges `RTCAudioSession` route updates into store state so downstream
    /// features can react to speaker/headset transitions.
    final class AVAudioSessionEffect: StoreEffect<RTCAudioStore.Namespace>, @unchecked Sendable {

        @Injected(\.avAudioSessionObserver) private var avAudioSessionObserver
        private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)
        private var audioDeviceModuleCancellable: AnyCancellable?
        private var avAudioSessionObserverCancellable: AnyCancellable?

        override init() {
            super.init()
        }

        override func set(
            statePublisher: AnyPublisher<RTCAudioStore.StoreState, Never>?
        ) {
            avAudioSessionObserverCancellable?.cancel()
            avAudioSessionObserverCancellable = nil
            avAudioSessionObserverCancellable?.cancel()
            avAudioSessionObserverCancellable = nil
            avAudioSessionObserver.stopObserving()

            guard let statePublisher else {
                return
            }

            audioDeviceModuleCancellable = statePublisher
                .map(\.audioDeviceModule)
                .removeDuplicates()
                .compactMap { $0 }
                .sink { [weak self] in self?.didUpdate($0) }
        }

        // MARK: - Private Helpers

        private func didUpdate(_ audioDeviceModule: AudioDeviceModule) {
            avAudioSessionObserverCancellable?.cancel()
            avAudioSessionObserverCancellable = nil
            avAudioSessionObserver.stopObserving()

            avAudioSessionObserverCancellable = avAudioSessionObserver
                .publisher
                .removeDuplicates()
                .sink { [weak self] in self?.didUpdate($0) }

            avAudioSessionObserver.startObserving()
        }

        private func didUpdate(_ state: AVAudioSession.Snapshot) {
            log.debug("AVAudioSession state updated: \(state).")

            dispatcher?.dispatch(
                [
                    .normal(.avAudioSession(.systemSetCategory(state.category))),
                    .normal(.avAudioSession(.systemSetMode(state.mode))),
                    .normal(.avAudioSession(.systemSetCategoryOptions(state.categoryOptions)))
                ]
            )
        }
    }
}
