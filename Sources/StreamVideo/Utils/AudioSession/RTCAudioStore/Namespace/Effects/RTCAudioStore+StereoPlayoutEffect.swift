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
        private var audioDeviceModuleCancellable: AnyCancellable?
        private var isStereoPlayoutAvailableCancellable: AnyCancellable?

        override func set(
            statePublisher: AnyPublisher<RTCAudioStore.StoreState, Never>?
        ) {
            guard let statePublisher else {
                return
            }

            let currentRoutePublisher = statePublisher
                .map(\.currentRoute)
                .removeDuplicates()
                .eraseToAnyPublisher()

            audioDeviceModuleCancellable = statePublisher
                .map(\.audioDeviceModule)
                .removeDuplicates()
                .receive(on: processingQueue)
                .log(.debug, subsystems: .audioSession) { "AudioDeviceModule was updated to \($0)." }
                .sink { [weak self] in self?.didUpdate(audioDeviceModule: $0, currentRoutePublisher: currentRoutePublisher) }
        }

        // MARK: - Private Helpers

        private func didUpdate(
            audioDeviceModule: AudioDeviceModule?,
            currentRoutePublisher: AnyPublisher<RTCAudioStore.StoreState.AudioRoute, Never>
        ) {
            isStereoPlayoutAvailableCancellable?.cancel()
            isStereoPlayoutAvailableCancellable = nil

            guard let audioDeviceModule else {
                return
            }

            let isStereoPlayoutAvailablePublisher = audioDeviceModule
                .isStereoPlayoutAvailablePublisher
                .removeDuplicates()
                .eraseToAnyPublisher()

            isStereoPlayoutAvailableCancellable = Publishers
                .CombineLatest(isStereoPlayoutAvailablePublisher, currentRoutePublisher)
                .receive(on: processingQueue)
                .throttle(for: 0.2, scheduler: processingQueue, latest: true)
                .log(.debug, subsystems: .audioSession) { "StereoPlayout updated to \($0)." }
                .sink { [weak self, weak audioDeviceModule] in self?.didUpdate(
                    audioDeviceModule: audioDeviceModule,
                    stereoPlayoutAvailable: $0.0
                ) }
        }

        private func didUpdate(
            audioDeviceModule: AudioDeviceModule?,
            stereoPlayoutAvailable: Bool
        ) {
            guard
                let audioDeviceModule
            else {
                return
            }

            dispatcher?.dispatch(.stereo(.setPlayoutAvailable(stereoPlayoutAvailable)))

            do {
                try audioDeviceModule.setStereoPlayoutEnabled(stereoPlayoutAvailable)
                dispatcher?.dispatch(.stereo(.setPlayoutEnabled(stereoPlayoutAvailable)))
            } catch {
                dispatcher?.dispatch(.stereo(.setPlayoutAvailable(false)))
                log.error(error, subsystems: .audioSession)
            }
        }
    }
}
