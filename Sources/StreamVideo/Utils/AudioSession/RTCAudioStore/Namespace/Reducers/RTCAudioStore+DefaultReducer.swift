//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

extension RTCAudioStore.Namespace {

    /// Handles simple state mutations that do not require direct WebRTC calls
    /// beyond what is already encoded in the action.
    final class DefaultReducer: Reducer<RTCAudioStore.Namespace>, @unchecked Sendable {

        private let source: AudioSessionProtocol

        init(_ source: AudioSessionProtocol) {
            self.source = source
            super.init()
        }

        /// Applies non-specialised store actions, mutating the state and
        /// performing lightweight side effects where needed.
        override func reduce(
            state: State,
            action: Action,
            file: StaticString,
            function: StaticString,
            line: UInt
        ) throws -> State {
            var updatedState = state

            switch action {
            case let .setActive(value):
                if value != source.isActive {
                    try source.perform {
                        try $0.setActive(value)
                        try $0.avSession.setIsActive(value)
                    }
                }
                updatedState.isActive = value

            case let .setInterrupted(value):
                updatedState.isInterrupted = value

            case let .setShouldRecord(value):
                updatedState.shouldRecord = value

            case let .setRecording(value):
                updatedState.isRecording = value

            case let .setMicrophoneMuted(value):
                updatedState.isMicrophoneMuted = value

            case let .setHasRecordingPermission(value):
                updatedState.hasRecordingPermission = value

            case let .setAudioDeviceModule(value):
                updatedState.audioDeviceModule = value
                if value == nil {
                    updatedState.shouldRecord = false
                    updatedState.isRecording = false
                    updatedState.isMicrophoneMuted = false
                }

            case let .setCurrentRoute(value):
                updatedState.currentRoute = value

            case .avAudioSession:
                break

            case .webRTCAudioSession:
                break

            case .callKit:
                break
            }

            return updatedState
        }
    }
}
