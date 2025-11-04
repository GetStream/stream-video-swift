//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
import StreamWebRTC

extension RTCAudioStore {

    final class HiFiMiddleware: Middleware<RTCAudioStore.Namespace>, @unchecked Sendable {

        private var isStereoAvailableCancellable: AnyCancellable?

        override func apply(
            state: RTCAudioStore.StoreState,
            action: RTCAudioStore.StoreAction,
            file: StaticString,
            function: StaticString,
            line: UInt
        ) {
            switch action {
            case let .setAudioDeviceModule(value):
                didUpdate(audioDeviceModule: value)

            default:
                break
            }
        }

        // MARK: - Private Helpers

        private func didUpdate(
            audioDeviceModule: AudioDeviceModule?
        ) {
            guard let audioDeviceModule else {
                isStereoAvailableCancellable?.cancel()
                isStereoAvailableCancellable = nil
                return
            }

            isStereoAvailableCancellable = audioDeviceModule
                .isStereoPlayoutAvailablePublisher
                .sink { [weak self] in self?.didUpdateStereoAvailability($0) }
        }

        private func didUpdateStereoAvailability(
            _ isAvailable: Bool
        ) {
            guard
                let audioDeviceModule = stateProvider?()?.audioDeviceModule
            else {
                return
            }

            dispatcher?.dispatch(.stereo(.setPlayoutAvailable(isAvailable)))

            do {
                try audioDeviceModule.setStereoPlayoutEnabled(
                    isAvailable
                )
                dispatcher?.dispatch(.stereo(.setPlayoutEnabled(isAvailable)))
                log.debug(
                    "Completed setStereoPlayoutEnabled:\(isAvailable) on audioDeviceModule:\(audioDeviceModule).",
                    subsystems: .audioSession
                )
            } catch {
                dispatcher?.dispatch(.stereo(.setPlayoutEnabled(false)))
                log.error(
                    error,
                    subsystems: .audioSession
                )
            }
        }
    }
}
