//
//  RTCAudioStore+Coordinator.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 10/10/25.
//

import Foundation

extension RTCAudioStore {

    final class Coordinator: StoreCoordinator<Namespace>, @unchecked Sendable {
        override func shouldExecute(
            action: StoreAction,
            state: StoreState
        ) -> Bool {
            switch action {
            case let .setActive(value):
                return value != state.isActive

            case let .setInterrupted(value):
                return value != state.isInterrupted

            case let .setShouldRecord(value):
                return value != state.shouldRecord

            case let .setRecording(value):
                return value != state.isRecording

            case let .setMicrophoneMuted(value):
                return value != state.isMicrophoneMuted

            case let .setHasRecordingPermission(value):
                return value != state.hasRecordingPermission

            case let .setPrefersHiFiPlayback(value):
                return value != state.prefersHiFiPlayback

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

            case .streamVideo:
                return true
            }
        }

        // MARK: - Private Helpers

        private func shouldExecute(
            action: StoreAction.AVAudioSessionAction,
            state: StoreState.AVAudioSessionConfiguration
        ) -> Bool {
            switch action {
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
                return category != state.category ||  mode != state.mode || categoryOptions != state.options

            case let .setOverrideOutputAudioPort(value):
                return value != state.overrideOutputAudioPort
            }
        }

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

    }
}
