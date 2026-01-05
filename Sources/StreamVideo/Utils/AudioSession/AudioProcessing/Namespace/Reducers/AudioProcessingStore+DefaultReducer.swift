//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Pure reducer that updates audio processing state in response to actions.

extension AudioProcessingStore.Namespace {

    final class DefaultReducer: Reducer<AudioProcessingStore.Namespace>, @unchecked Sendable {

        /// Applies the given action and returns updated state.
        override func reduce(
            state: AudioProcessingStore.Namespace.StoreState,
            action: AudioProcessingStore.Namespace.StoreAction,
            file: StaticString,
            function: StaticString,
            line: UInt
        ) async throws -> AudioProcessingStore.Namespace.StoreState {
            var updatedState = state

            switch action {
            case .load:
                break

            case let .setInitializedConfiguration(sampleRate, channels):
                updatedState.initializedSampleRate = sampleRate
                updatedState.initializedChannels = channels

            case let .setAudioFilter(value):
                updatedState.audioFilter = value

            case let .setNumberOfCaptureChannels(value):
                updatedState.numberOfCaptureChannels = value

            case .release:
                updatedState.initializedSampleRate = 0
                updatedState.initializedChannels = 0
                updatedState.audioFilter = nil
            }

            return updatedState
        }
    }
}
