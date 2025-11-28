//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension RTCAudioStore {

    /// Skips redundant store work by evaluating whether an action would mutate
    /// the current state before allowing reducers to run.
    final class Coordinator: StoreCoordinator<Namespace>, @unchecked Sendable {
        /// Returns `true` when reducers should execute for the given action and
        /// state combination.
        override func shouldExecute(
            action: StoreAction,
            state: StoreState
        ) -> Bool {
            switch action {
            case let .setActive(value):
                return value != state.isActive

            case let .setInterrupted(value):
                return value != state.isInterrupted

            case let .setRecording(value):
                return value != state.isRecording

            case let .audioDeviceModuleSetRecording(value):
                return value != state.isRecording

            case let .setMicrophoneMuted(value):
                return value != state.isMicrophoneMuted

            case let .setHasRecordingPermission(value):
                return value != state.hasRecordingPermission

            case let .setAudioDeviceModule(value):
                return value !== state.audioDeviceModule

            case let .setCurrentRoute(value):
                return value != state.currentRoute

            case let .avAudioSession(value):
                return shouldExecute(
                    action: value,
                    state: state.audioSessionConfiguration
                )

            case let .webRTCAudioSession(value):
                return shouldExecute(
                    action: value,
                    state: state.webRTCAudioSessionConfiguration
                )

            case .callKit:
                return true
                
            case let .stereo(value):
                return shouldExecute(
                    action: value,
                    state: state.stereoConfiguration
                )
            }
        }

        // MARK: - Private Helpers

        /// Determines if an AVAudioSession action would alter the configuration.
        private func shouldExecute(
            action: StoreAction.AVAudioSessionAction,
            state: StoreState.AVAudioSessionConfiguration
        ) -> Bool {
            switch action {
            case let .systemSetCategory(value):
                return value != state.category

            case let .systemSetMode(value):
                return value != state.mode

            case let .systemSetCategoryOptions(value):
                return value != state.options

            case let .setCategory(value):
                return value != state.category

            case let .setMode(value):
                return value != state.mode

            case let .setCategoryOptions(value):
                return value != state.options

            case let .setCategoryAndMode(category, mode):
                return category != state.category || mode != state.mode

            case let .setCategoryAndCategoryOptions(category, categoryOptions):
                return category != state.category || categoryOptions != state.options

            case let .setModeAndCategoryOptions(mode, categoryOptions):
                return mode != state.mode || categoryOptions != state.options

            case let .setCategoryAndModeAndCategoryOptions(category, mode, categoryOptions):
                return category != state.category || mode != state.mode || categoryOptions != state.options

            case let .setOverrideOutputAudioPort(value):
                return value != state.overrideOutputAudioPort
            }
        }

        /// Determines if a WebRTC action would change the tracked configuration.
        private func shouldExecute(
            action: StoreAction.WebRTCAudioSessionAction,
            state: StoreState.WebRTCAudioSessionConfiguration
        ) -> Bool {
            switch action {
            case let .setAudioEnabled(value):
                return value != state.isAudioEnabled

            case let .setUseManualAudio(value):
                return value != state.useManualAudio

            case let .setPrefersNoInterruptionsFromSystemAlerts(value):
                return value != state.prefersNoInterruptionsFromSystemAlerts
            }
        }

        private func shouldExecute(
            action: StoreAction.StereoAction,
            state: StoreState.StereoConfiguration
        ) -> Bool {
            switch action {
            case let .setPlayoutPreferred(value):
                state.playout.preferred != value

            case let .setPlayoutEnabled(value):
                state.playout.enabled != value
            }
        }
    }
}
