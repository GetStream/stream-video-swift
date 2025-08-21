//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation

extension RTCAudioStore {

    final class HiFiEffect {
        @Injected(\.orientationAdapter) private var orientationAdapter

        /// A weak reference to the `RTCAudioStore` to dispatch state changes.
        private weak var store: RTCAudioStore?

        private let audioSession: AVAudioSessionProtocol
        private let disposableBag = DisposableBag()

        private var isActive: Bool = false

        init(_ store: RTCAudioStore) {
            self.store = store
            audioSession = store.session.avSession

            let isActivePublisher = store.publisher(\.isActive).eraseToAnyPublisher()
            let inputConfigurationPublisher = store.publisher(\.inputConfiguration).eraseToAnyPublisher()
            let categoryPublisher = store.publisher(\.category).eraseToAnyPublisher()

            Publishers
                .CombineLatest3(
                    isActivePublisher,
                    inputConfigurationPublisher,
                    categoryPublisher
                )
                .map { (isActive: $0.0, inputConfiguration: $0.1, category: $0.2) }
                .removeDuplicates { $0 == $1 }
                .sink { [weak self] in
                    self?.process(
                        isSessionActive: $0.isActive,
                        inputConfiguration: $0.inputConfiguration,
                        category: $0.category
                    )
                }
                .store(in: disposableBag)

            // TODO: Observe orientation changes and audio position updates
        }

        // MARK: - Private Helpers

        private func process(
            isSessionActive: Bool,
            inputConfiguration: State.InputConfiguration,
            category: AVAudioSession.Category
        ) {
            let isStereoEnabled = inputConfiguration.inputType == .stereo
            switch (isActive, isSessionActive, isStereoEnabled, category) {
            case (false, true, true, .playAndRecord):
                activate()
            case (true, _, _, _):
                deactivate()
            default:
                break
            }
        }

        private func activate() {
            do {
                try audioSession.enableBuiltInMic()
                try audioSession.setStereoAudioPosition(
                    .front,
                    deviceOrientation: orientationAdapter.orientation
                )
                isActive = true
                log.debug("HiFi has been activated.", subsystems: .audioSession)
            } catch {
                log.error(error, subsystems: .audioSession)
            }
        }

        private func deactivate() {
            do {
                try audioSession.resetInputPreferences()
                isActive = false
                log.debug("HiFi has been deactivated.", subsystems: .audioSession)
            } catch {
                log.error(error, subsystems: .audioSession)
            }
        }
    }
}
