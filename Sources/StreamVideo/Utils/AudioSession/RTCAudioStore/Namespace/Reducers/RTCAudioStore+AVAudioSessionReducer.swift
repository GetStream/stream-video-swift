//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
import StreamWebRTC

extension RTCAudioStore.Namespace {

    /// Applies `AVAudioSession` specific actions to both the live WebRTC session
    /// and the store state, keeping them aligned.
    final class AVAudioSessionReducer: Reducer<RTCAudioStore.Namespace>, @unchecked Sendable {

        private let source: AudioSessionProtocol

        init(_ source: AudioSessionProtocol) {
            self.source = source
        }

        /// Handles `StoreAction.avAudioSession` cases by mutating the session and
        /// returning an updated state snapshot.
        override func reduce(
            state: State,
            action: Action,
            file: StaticString,
            function: StaticString,
            line: UInt
        ) async throws -> State {
            var updatedState = state

            if case let .setCurrentRoute(value) = action {
                updatedState.audioSessionConfiguration.overrideOutputAudioPort = value.isSpeaker ? .speaker : .none
            }

            guard case let .avAudioSession(action) = action else {
                return updatedState
            }

            switch action {
            case let .systemSetCategory(value):
                updatedState.audioSessionConfiguration.category = value

            case let .systemSetMode(value):
                updatedState.audioSessionConfiguration.mode = value

            case let .systemSetCategoryOptions(value):
                updatedState.audioSessionConfiguration.options = value

            case let .setCategory(value):
                try performUpdate(
                    state: state.audioSessionConfiguration,
                    category: value,
                    mode: state.audioSessionConfiguration.mode,
                    categoryOptions: state.audioSessionConfiguration.options
                )
                updatedState.audioSessionConfiguration.category = value
                updatedState.audioSessionConfiguration.overrideOutputAudioPort = .none

            case let .setMode(value):
                try performUpdate(
                    state: state.audioSessionConfiguration,
                    category: state.audioSessionConfiguration.category,
                    mode: value,
                    categoryOptions: state.audioSessionConfiguration.options
                )
                updatedState.audioSessionConfiguration.mode = value
                updatedState.audioSessionConfiguration.overrideOutputAudioPort = .none

            case let .setCategoryOptions(value):
                try performUpdate(
                    state: state.audioSessionConfiguration,
                    category: state.audioSessionConfiguration.category,
                    mode: state.audioSessionConfiguration.mode,
                    categoryOptions: value
                )
                updatedState.audioSessionConfiguration.options = value
                updatedState.audioSessionConfiguration.overrideOutputAudioPort = .none

            case let .setCategoryAndMode(category, mode):
                try performUpdate(
                    state: state.audioSessionConfiguration,
                    category: category,
                    mode: mode,
                    categoryOptions: state.audioSessionConfiguration.options
                )
                updatedState.audioSessionConfiguration.category = category
                updatedState.audioSessionConfiguration.mode = mode
                updatedState.audioSessionConfiguration.overrideOutputAudioPort = .none

            case let .setCategoryAndCategoryOptions(category, categoryOptions):
                try performUpdate(
                    state: state.audioSessionConfiguration,
                    category: category,
                    mode: state.audioSessionConfiguration.mode,
                    categoryOptions: categoryOptions
                )
                updatedState.audioSessionConfiguration.category = category
                updatedState.audioSessionConfiguration.options = categoryOptions
                updatedState.audioSessionConfiguration.overrideOutputAudioPort = .none

            case let .setModeAndCategoryOptions(mode, categoryOptions):
                try performUpdate(
                    state: state.audioSessionConfiguration,
                    category: state.audioSessionConfiguration.category,
                    mode: mode,
                    categoryOptions: categoryOptions
                )
                updatedState.audioSessionConfiguration.mode = mode
                updatedState.audioSessionConfiguration.options = categoryOptions
                updatedState.audioSessionConfiguration.overrideOutputAudioPort = .none

            case let .setCategoryAndModeAndCategoryOptions(category, mode, categoryOptions):
                try performUpdate(
                    state: state.audioSessionConfiguration,
                    category: category,
                    mode: mode,
                    categoryOptions: categoryOptions
                )
                updatedState.audioSessionConfiguration.category = category
                updatedState.audioSessionConfiguration.mode = mode
                updatedState.audioSessionConfiguration.options = categoryOptions
                updatedState.audioSessionConfiguration.overrideOutputAudioPort = .none

            case let .setOverrideOutputAudioPort(value):
                if state.audioSessionConfiguration.category == .playAndRecord {
                    try source.perform {
                        try $0.overrideOutputAudioPort(value)
                    }
                    updatedState.audioSessionConfiguration.overrideOutputAudioPort = value
                } else {
                    updatedState = try await setDefaultToSpeaker(
                        state: state,
                        speakerOn: value == .speaker
                    )
                }
            }

            return updatedState
        }

        // MARK: - Private Helpers

        /// Ensures the requested configuration is valid, applies it to the
        /// session, and returns the canonicalised state.
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
                log.debug(
                    "AVAudioSession configuration didn't change category:\(category), mode:\(mode), categoryOptions:\(categoryOptions).",
                    subsystems: .audioSession
                )
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
                throw ClientError(
                    "Invalid AVAudioSession configuration category:\(category) mode:\(mode) options:\(categoryOptions)."
                )
            }

            let requiresRestart = source.isActive

            let webRTCConfiguration = RTCAudioSessionConfiguration.webRTC()
            webRTCConfiguration.category = category.rawValue
            webRTCConfiguration.mode = mode.rawValue
            webRTCConfiguration.categoryOptions = categoryOptions

            try source.perform { session in
                if requiresRestart {
                    try session.setActive(false)
                }

                try session.setConfiguration(
                    webRTCConfiguration,
                    active: requiresRestart
                )
            }

            /// We update the `webRTC` default configuration because, the WebRTC audioStack
            /// can be restarted for various reasons. When the stack restarts it gets reconfigured
            /// with the `webRTC` configuration. If then the configuration is invalid compared
            /// to the state we expect we may find ourselves in a difficult to recover situation,
            /// as our callSetting may be failing to get applied.
            /// By updating the `webRTC` configuration we ensure that the audioStack will
            /// start from the last known state in every restart, making things simpler to recover.
            RTCAudioSessionConfiguration.setWebRTC(webRTCConfiguration)
        }

        /// Updates the `defaultToSpeaker` option to mirror a requested override.
        private func setDefaultToSpeaker(
            state: State,
            speakerOn: Bool
        ) async throws -> State {
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
                return state
            }

            return try await reduce(
                state: state,
                action: .avAudioSession(.setCategoryOptions(categoryOptions)),
                file: #file,
                function: #function,
                line: #line
            )
        }
    }
}
