//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension CallAudioRecordingStore {

    final class DefaultReducer: CallAudioRecordingReducer {

        func reduce(
            state: CallAudioRecordingStore.State,
            action: CallAudioRecordingAction,
            file: StaticString,
            function: StaticString,
            line: UInt
        ) throws -> CallAudioRecordingStore.State {
            var updatedState = state

            switch action {
            case let .setIsRecording(value):
                updatedState.isRecording = value

            case let .setIsInterrupted(value):
                updatedState.isInterrupted = value

            case let .setShouldRecord(value):
                updatedState.shouldRecord = value

            case let .setMeter(value):
                updatedState.meter = value
            }

            return updatedState
        }
    }
}
