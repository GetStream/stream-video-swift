//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
        ) async throws -> State {
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
                try updatedState.audioDeviceModule?.setPlayout(value)

            case let .setInterrupted(value):
                updatedState.isInterrupted = value

            case let .setRecording(value):
                updatedState.isRecording = value

            case let .audioDeviceModuleSetRecording(value):
                updatedState.isRecording = value

            case let .setMicrophoneMuted(value):
                updatedState.isMicrophoneMuted = value

            case let .setHasRecordingPermission(value):
                updatedState.hasRecordingPermission = value

            case let .setAudioDeviceModule(value):
                updatedState.audioDeviceModule = value
                if value == nil {
                    updatedState.isRecording = false
                    updatedState.isMicrophoneMuted = true
                    updatedState.stereoConfiguration = .init(
                        playout: .init(
                            preferred: false,
                            enabled: false
                        )
                    )
                }

            case let .setCurrentRoute(value):
                updatedState.currentRoute = value

            case let .stereo(.setPlayoutPreferred(value)):
                updatedState.stereoConfiguration.playout.preferred = value

            case let .stereo(.setPlayoutEnabled(value)):
                updatedState.stereoConfiguration.playout.enabled = value

            case .avAudioSession:
                break

            case .webRTCAudioSession:
                break

            case .stereo:
                break

            case .callKit:
                break
            }

            return updatedState
        }
    }
}
