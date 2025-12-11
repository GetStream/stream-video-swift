//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation

extension RTCAudioStore {

    /// Observes the audio device module to detect when stereo playout becomes
    /// available, keeping the store's stereo state aligned with WebRTC.
    final class StereoPlayoutEffect: StoreEffect<RTCAudioStore.Namespace>, @unchecked Sendable {

        private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)
        private let disposableBag = DisposableBag()
        private var audioDeviceModuleCancellable: AnyCancellable?

        override func set(
            statePublisher: AnyPublisher<RTCAudioStore.StoreState, Never>?
        ) {
            audioDeviceModuleCancellable?.cancel()
            audioDeviceModuleCancellable = nil
            processingQueue.cancelAllOperations()
            disposableBag.removeAll()

            guard let statePublisher else {
                return
            }

            audioDeviceModuleCancellable = statePublisher
                .map(\.audioDeviceModule)
                .removeDuplicates()
                .receive(on: processingQueue)
                .sink { [weak self] in self?.didUpdate(audioDeviceModule: $0, statePublisher: statePublisher) }
        }

        // MARK: - Private Helpers

        private func didUpdate(
            audioDeviceModule: AudioDeviceModule?,
            statePublisher: AnyPublisher<RTCAudioStore.StoreState, Never>
        ) {
            disposableBag.removeAll()

            guard let audioDeviceModule else {
                return
            }

            /// This is important to support cases (e.g. a wired headphone) that do not trigger a valid
            /// route change for WebRTC causing the user to join the call without stereo and requiring
            /// either toggling the speaker or reconnect their wired headset.
            statePublisher
                .map(\.currentRoute)
                .removeDuplicates()
                .debounce(for: .seconds(2), scheduler: processingQueue)
                .sink { [weak audioDeviceModule] _ in audioDeviceModule?.refreshStereoPlayoutState() }
                .store(in: disposableBag)

            audioDeviceModule
                .isStereoPlayoutEnabledPublisher
                .removeDuplicates()
                .receive(on: processingQueue)
                .sink { [weak self] in self?.dispatcher?.dispatch(.stereo(.setPlayoutEnabled($0))) }
                .store(in: disposableBag)
        }
    }
}
