//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
import StreamWebRTC

extension RTCAudioStore {

    /// Bridges `RTCAudioSession` route updates into store state so downstream
    /// features can react to speaker/headset transitions.
    final class StereoPlayoutAvailabilityReducer: Reducer<RTCAudioStore.Namespace>, @unchecked Sendable {

        override func reduce(
            state: RTCAudioStore.StoreState,
            action: RTCAudioStore.StoreAction,
            file: StaticString,
            function: StaticString,
            line: UInt
        ) async throws -> RTCAudioStore.StoreState {
            switch action {
            case let .setCurrentRoute(value):
                didUpdate(
                    currentRoute: value,
                    mode: state.audioSessionConfiguration.mode
                )

            case let .avAudioSession(.setMode(value)):
                didUpdate(
                    currentRoute: state.currentRoute,
                    mode: value
                )

            case let .avAudioSession(.setCategoryAndMode(_, mode)):
                didUpdate(
                    currentRoute: state.currentRoute,
                    mode: mode
                )

            case let .avAudioSession(.setModeAndCategoryOptions(mode, _)):
                didUpdate(
                    currentRoute: state.currentRoute,
                    mode: mode
                )

            case let .avAudioSession(.setCategoryAndModeAndCategoryOptions(_, mode, _)):
                didUpdate(
                    currentRoute: state.currentRoute,
                    mode: mode
                )

            default:
                break
            }

            return state
        }

        // MARK: - Private Helpers

        private func didUpdate(
            currentRoute: RTCAudioStore.StoreState.AudioRoute,
            mode: AVAudioSession.Mode
        ) {
            guard
                currentRoute.supportsStereoOutput,
                mode.supportsStereoPlayout
            else {
                log.info(
                    "Stereo playout for currentRouteSupport:\(currentRoute.supportsStereoOutput) modeSupport:\(mode.supportsStereoPlayout) is unavailable.",
                    subsystems: .audioSession
                )
                dispatcher?.dispatch(.stereo(.setPlayoutAvailable(false)))
                return
            }
            dispatcher?.dispatch(.stereo(.setPlayoutAvailable(true)))
        }
    }
}
