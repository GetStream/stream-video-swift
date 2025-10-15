//
//  RTCAudioStore+AVAudioSessionReducer.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 9/10/25.
//

import Foundation
import StreamWebRTC
import AVFoundation

extension RTCAudioStore.Namespace {

    final class AVAudioSessionReducer: Reducer<RTCAudioStore.Namespace>, @unchecked Sendable {

        private let source: RTCAudioSession

        init(_ source: RTCAudioSession) {
            self.source = source
        }

        override func reduce(
            state: State,
            action: Action,
            file: StaticString,
            function: StaticString,
            line: UInt
        ) throws -> State {
            switch action {
            case let .setPrefersHiFiPlayback(value):
                var updatedState = state
                let targetMode = rewriteModeForStereoPlayoutIfRequired(value, mode: state.audioSessionConfiguration.mode)
                try performUpdate(
                    state: state.audioSessionConfiguration,
                    category: state.audioSessionConfiguration.category,
                    mode: targetMode,
                    categoryOptions: state.audioSessionConfiguration.options
                )
                updatedState.audioSessionConfiguration.mode = targetMode
                return updatedState

            case let .avAudioSession(action):
                return try processAVAudioSessionAction(
                    state: state,
                    action: action,
                    file: file,
                    function: function,
                    line: line
                )

            default:
                return state
            }
        }

        // MARK: - Private Helpers

        private func processAVAudioSessionAction(
            state: State,
            action: RTCAudioStore.StoreAction.AVAudioSessionAction,
            file: StaticString,
            function: StaticString,
            line: UInt
        ) throws -> State {
            var updatedState = state

            switch action {
            case let .setCategory(value):
                try performUpdate(
                    state: state.audioSessionConfiguration,
                    category: value,
                    mode: state.audioSessionConfiguration.mode,
                    categoryOptions: state.audioSessionConfiguration.options
                )
                updatedState.audioSessionConfiguration.category = value

            case let .setMode(value):
                let targetMode = rewriteModeForStereoPlayoutIfRequired(state.prefersHiFiPlayback, mode: value)
                try performUpdate(
                    state: state.audioSessionConfiguration,
                    category: state.audioSessionConfiguration.category,
                    mode: targetMode,
                    categoryOptions: state.audioSessionConfiguration.options
                )
                updatedState.audioSessionConfiguration.mode = targetMode

            case let .setCategoryOptions(value):
                let targetOptions = rewriteCategoryOptionsForStereoPlayoutIfRequired(
                    state.prefersHiFiPlayback,
                    options: value
                )
                try performUpdate(
                    state: state.audioSessionConfiguration,
                    category: state.audioSessionConfiguration.category,
                    mode: state.audioSessionConfiguration.mode,
                    categoryOptions: targetOptions
                )
                updatedState.audioSessionConfiguration.options = targetOptions

            case let .setCategoryAndMode(category, mode):
                let targetMode = rewriteModeForStereoPlayoutIfRequired(
                    state.prefersHiFiPlayback,
                    mode: mode
                )
                try performUpdate(
                    state: state.audioSessionConfiguration,
                    category: category,
                    mode: targetMode,
                    categoryOptions: state.audioSessionConfiguration.options
                )
                updatedState.audioSessionConfiguration.category = category
                updatedState.audioSessionConfiguration.mode = targetMode

            case let .setCategoryAndCategoryOptions(category, categoryOptions):
                let targetOptions = rewriteCategoryOptionsForStereoPlayoutIfRequired(
                    state.prefersHiFiPlayback,
                    options: categoryOptions
                )
                try performUpdate(
                    state: state.audioSessionConfiguration,
                    category: category,
                    mode: state.audioSessionConfiguration.mode,
                    categoryOptions: targetOptions
                )
                updatedState.audioSessionConfiguration.category = category
                updatedState.audioSessionConfiguration.options = targetOptions

            case let .setModeAndCategoryOptions(mode, categoryOptions):
                let targetMode = rewriteModeForStereoPlayoutIfRequired(
                    state.prefersHiFiPlayback,
                    mode: mode
                )
                let targetOptions = rewriteCategoryOptionsForStereoPlayoutIfRequired(
                    state.prefersHiFiPlayback,
                    options: categoryOptions
                )
                try performUpdate(
                    state: state.audioSessionConfiguration,
                    category: state.audioSessionConfiguration.category,
                    mode: targetMode,
                    categoryOptions: targetOptions
                )
                updatedState.audioSessionConfiguration.mode = targetMode
                updatedState.audioSessionConfiguration.options = targetOptions

            case let .setCategoryAndModeAndCategoryOptions(category, mode, categoryOptions):
                let targetMode = rewriteModeForStereoPlayoutIfRequired(
                    state.prefersHiFiPlayback,
                    mode: mode
                )
                let targetOptions = rewriteCategoryOptionsForStereoPlayoutIfRequired(
                    state.prefersHiFiPlayback,
                    options: categoryOptions
                )
                try performUpdate(
                    state: state.audioSessionConfiguration,
                    category: category,
                    mode: targetMode,
                    categoryOptions: targetOptions
                )
                updatedState.audioSessionConfiguration.category = category
                updatedState.audioSessionConfiguration.mode = targetMode
                updatedState.audioSessionConfiguration.options = targetOptions

            case let .setOverrideOutputAudioPort(value):
                try performUpdate(
                    state: state.audioSessionConfiguration,
                    overrideOutputAudioPort: value
                )
                updatedState.audioSessionConfiguration.overrideOutputAudioPort = value
            }

            return updatedState
        }

        private func rewriteModeForStereoPlayoutIfRequired(
            _ isStereoPlayoutEnabled: Bool,
            mode: AVAudioSession.Mode
        ) -> AVAudioSession.Mode {
            guard
                isStereoPlayoutEnabled,
                mode != .default
            else {
                return mode
            }

            return .default
        }

        private func rewriteCategoryOptionsForStereoPlayoutIfRequired(
            _ isStereoPlayoutEnabled: Bool,
            options: AVAudioSession.CategoryOptions
        ) -> AVAudioSession.CategoryOptions {
            guard
                isStereoPlayoutEnabled,
                options.contains(.allowBluetoothHFP) || options.contains(.allowBluetooth)
            else {
                return options
            }

            let result = options.subtracting([.allowBluetoothHFP, .allowBluetooth])
            return result
        }

        private func performUpdate(
            state: State.AVAudioSessionConfiguration,
            category: AVAudioSession.Category,
            mode: AVAudioSession.Mode,
            categoryOptions: AVAudioSession.CategoryOptions
        ) throws {
            guard
                state.category != category
                    || state.mode != mode
                    || state.options != categoryOptions
            else {
                return
            }

            guard
                State.AVAudioSessionConfiguration(
                    category: category,
                    mode: mode,
                    options: categoryOptions,
                    overrideOutputAudioPort: state.overrideOutputAudioPort
                ).isValid
            else {
                throw ClientError("Invalid AVAudioSession configuration category:\(category) mode:\(mode) options:\(categoryOptions).")
            }

            source.lockForConfiguration()
            defer { source.unlockForConfiguration() }

            /// We update the `webRTC` default configuration because, the WebRTC audioStack
            /// can be restarted for various reasons. When the stack restarts it gets reconfigured
            /// with the `webRTC` configuration. If then the configuration is invalid compared
            /// to the state we expect we may find ourselves in a difficult to recover situation,
            /// as our callSetting may be failing to get applied.
            /// By updating the `webRTC` configuration we ensure that the audioStack will
            /// start from the last known state in every restart, making things simpler to recover.
            let webRTCConfiguration = RTCAudioSessionConfiguration.webRTC()
            webRTCConfiguration.category = category.rawValue
            webRTCConfiguration.mode = mode.rawValue
            webRTCConfiguration.categoryOptions = categoryOptions

            let requiresRestart = source.isActive

            if requiresRestart { try source.setActive(false) }
            try source.setConfiguration(webRTCConfiguration, active: requiresRestart)
            RTCAudioSessionConfiguration.setWebRTC(webRTCConfiguration)
        }

        private func performUpdate(
            state: State.AVAudioSessionConfiguration,
            overrideOutputAudioPort: AVAudioSession.PortOverride
        ) throws {
            guard
                state.overrideOutputAudioPort != overrideOutputAudioPort
            else {
                return
            }

            if state.category == .playAndRecord {
                source.lockForConfiguration()
                defer { source.unlockForConfiguration() }
                try source.overrideOutputAudioPort(overrideOutputAudioPort)
            } else {
                try setDefaultToSpeaker(
                    state: state,
                    speakerOn: overrideOutputAudioPort == .speaker
                )
            }
        }

        private func setDefaultToSpeaker(
            state: State.AVAudioSessionConfiguration,
            speakerOn: Bool
        ) throws {
            var categoryOptions = source.categoryOptions
            let defaultToSpeakerExists = categoryOptions.contains(.defaultToSpeaker)

            var didUpdate = false
            switch (speakerOn, defaultToSpeakerExists) {
            case (true, false):
                categoryOptions.insert(.defaultToSpeaker)
                didUpdate = true

            case (false, true):
                categoryOptions.remove(.defaultToSpeaker)
                didUpdate = true

            default:
                break
            }

            guard didUpdate else {
                return
            }

            try performUpdate(
                state: state,
                category: state.category,
                mode: state.mode,
                categoryOptions: categoryOptions
            )
        }
    }
}
