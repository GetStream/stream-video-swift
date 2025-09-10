//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension LocalAudioMediaAdapter.Namespace {

    final class DefaultReducer: Reducer<LocalAudioMediaAdapter.Namespace>, @unchecked Sendable {

        override func reduce(
            state: LocalAudioMediaAdapter.Namespace.StoreState,
            action: LocalAudioMediaAdapter.Namespace.StoreAction,
            file: StaticString,
            function: StaticString,
            line: UInt
        ) throws -> LocalAudioMediaAdapter.Namespace.StoreState {
            var updatedState = state
            switch action {
            case let .setCallSettings(value):
                updatedState.callSettings = value

            case let .setOwnCapabilities(value):
                updatedState.ownCapabilities = value

            case let .setPublishingState(value, availableTrackStates):
                updatedState.publishingState = value
                updatedState.availableTrackStates = availableTrackStates

            case let .setPublishOptions(value):
                updatedState.publishOptions = value

            case let .setAudioBitrateAndMediaConstraints(audioBitrate, mediaConstraints):
                updatedState.audioBitrate = audioBitrate
                updatedState.mediaConstraints = mediaConstraints
            }

            return updatedState
        }
    }
}
