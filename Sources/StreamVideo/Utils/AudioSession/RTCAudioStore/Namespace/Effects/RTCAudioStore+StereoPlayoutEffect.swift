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
        private let setStereoPlayoutSubject: PassthroughSubject<Bool, Never> = .init()
        private let disposableBag = DisposableBag()
        private var audioDeviceModuleCancellable: AnyCancellable?

        override func set(
            statePublisher: AnyPublisher<RTCAudioStore.StoreState, Never>?
        ) {
            audioDeviceModuleCancellable?.cancel()
            audioDeviceModuleCancellable = nil

            guard let statePublisher else {
                return
            }

            audioDeviceModuleCancellable = statePublisher
                .map(\.audioDeviceModule)
                .removeDuplicates()
                .receive(on: processingQueue)
                .log(.debug, subsystems: .audioSession) { "AudioDeviceModule was updated to \($0)." }
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

            setStereoPlayoutSubject
                .receive(on: processingQueue)
                .sink { [weak audioDeviceModule] enableStereoPlayout in
                    log.throwing("Unable to setStereoPlayout:\(enableStereoPlayout)", subsystems: .audioSession) {
                        try audioDeviceModule?.setStereoPlayoutEnabled(enableStereoPlayout)
                    }
                }
                .store(in: disposableBag)

            audioDeviceModule
                .isStereoPlayoutAvailablePublisher
                .removeDuplicates()
                .receive(on: processingQueue)
                .sink { [weak self] in self?.dispatcher?.dispatch(.stereo(.setPlayoutAvailable($0))) }
                .store(in: disposableBag)

            audioDeviceModule
                .isStereoPlayoutEnabledPublisher
                .removeDuplicates()
                .receive(on: processingQueue)
                .sink { [weak self] in self?.dispatcher?.dispatch(.stereo(.setPlayoutEnabled($0))) }
                .store(in: disposableBag)

            Publishers
                .CombineLatest(
                    audioDeviceModule
                        .isStereoPlayoutAvailablePublisher
                        .eraseToAnyPublisher(),
                    statePublisher
                        .map(\.currentRoute)
                        .removeDuplicates()
                        .map(\.supportsStereoOutput)
                )
                .debounce(for: .seconds(1), scheduler: processingQueue)
                .receive(on: processingQueue)
                .log(.debug, subsystems: .audioSession) {
                    "Received an update { stereoPlayoutAvailable:\($0.0), currentRouteSupportsStereoOutput:\($0.1), resolved:\($0.0 && $0.1) }"
                }
                .map { $0.0 && $0.1 }
                .sink { [weak self] in self?.setStereoPlayoutSubject.send($0) }
                .store(in: disposableBag)
        }
    }
}
