//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation

extension RTCAudioStore {

    /// Converts audio session interruption callbacks into store actions so the
    /// audio pipeline can gracefully pause and resume.
    final class StereoPlayoutEffect: StoreEffect<RTCAudioStore.Namespace>, @unchecked Sendable {

        private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)
        private var cancellable: AnyCancellable?

        override func set(
            statePublisher: AnyPublisher<RTCAudioStore.StoreState, Never>?
        ) {
            cancellable?.cancel()
            cancellable = nil

            guard let statePublisher else {
                return
            }

            let audioDeviceModulePublisher = statePublisher
                .map(\.audioDeviceModule)
                .eraseToAnyPublisher()

            let stereoPlayoutAvailable = statePublisher
                .filter { $0.audioDeviceModule != nil }
                .map(\.stereoConfiguration.playout.available)
                .eraseToAnyPublisher()

            let currentRoutePublisher = statePublisher
                .filter { $0.audioDeviceModule != nil }
                .map(\.currentRoute)
                .eraseToAnyPublisher()

            cancellable = Publishers
                .CombineLatest3(
                    audioDeviceModulePublisher,
                    stereoPlayoutAvailable,
                    currentRoutePublisher
                )
                .filter { $0.2.supportsStereoOutput }
                .throttle(for: 0.5, scheduler: processingQueue, latest: true)
                .receive(on: processingQueue)
                .sink { [weak self] in self?.didUpdate(audioDeviceModule: $0.0, stereoPlayoutEnabled: $0.1) }
        }

        // MARK: - Private Helpers

        private func didUpdate(
            audioDeviceModule: AudioDeviceModule?,
            stereoPlayoutEnabled: Bool
        ) {
            guard
                let audioDeviceModule,
                stereoPlayoutEnabled == audioDeviceModule.isStereoPlayoutAvailable
            else {
                return
            }

            do {
                try audioDeviceModule.setStereoPlayoutEnabled(stereoPlayoutEnabled)
                dispatcher?.dispatch(.stereo(.setPlayoutEnabled(stereoPlayoutEnabled)))
            } catch {
                log.error(error, subsystems: .audioSession)
            }
        }
    }
}
