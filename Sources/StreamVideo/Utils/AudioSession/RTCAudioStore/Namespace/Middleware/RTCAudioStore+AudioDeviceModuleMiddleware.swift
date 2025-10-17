//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
import StreamWebRTC

extension RTCAudioStore {

    /// Keeps the `AudioDeviceModule` in sync with store-driven intent and
    /// propagates ADM state changes back into the store.
    final class AudioDeviceModuleMiddleware: Middleware<RTCAudioStore.Namespace>, @unchecked Sendable {

        private let disposableBag = DisposableBag()

        /// Responds to store actions that require interacting with the ADM or
        /// listening for its publisher output.
        override func apply(
            state: RTCAudioStore.StoreState,
            action: RTCAudioStore.StoreAction,
            file: StaticString,
            function: StaticString,
            line: UInt
        ) {
            guard
                let audioDeviceModule = state.audioDeviceModule
            else {
                return
            }

            switch action {
            case let .setInterrupted(value):
                log.throwing(
                    "Unable to process setInterrupted:\(value).",
                    subsystems: .audioSession
                ) {
                    try didSetInterrupted(
                        value,
                        state: state,
                        audioDeviceModule: audioDeviceModule
                    )
                }

            case let .setShouldRecord(value):
                log.throwing(
                    "Unable to process setShouldRecord:\(value).",
                    subsystems: .audioSession
                ) {
                    try didSetShouldRecord(
                        value,
                        state: state,
                        audioDeviceModule: audioDeviceModule
                    )
                }

            case let .setMicrophoneMuted(value):
                log.throwing(
                    "Unable to process setMicrophoneMuted:\(value).",
                    subsystems: .audioSession
                ) {
                    try didSetMicrophoneMuted(
                        value,
                        state: state,
                        audioDeviceModule: audioDeviceModule
                    )
                }

            case let .setAudioDeviceModule(value):
                log.throwing(
                    "Unable to process setAudioDeviceModule:\(value).",
                    subsystems: .audioSession
                ) {
                    try didSetAudioDeviceModule(
                        value,
                        state: state
                    )
                }

            case .setActive:
                break
            case .setRecording:
                break
            case .setHasRecordingPermission:
                break
            case .setCurrentRoute:
                break
            case .avAudioSession:
                break
            case .webRTCAudioSession:
                break
            case .callKit:
                break
            }
        }

        // MARK: - Private Helpers

        /// Reacts to interruption updates by suspending or resuming ADM
        /// recording as needed.
        private func didSetInterrupted(
            _ value: Bool,
            state: RTCAudioStore.StoreState,
            audioDeviceModule: AudioDeviceModule
        ) throws {
            guard
                state.isActive,
                state.shouldRecord
            else {
                return
            }

            if value {
                try audioDeviceModule.setRecording(false)
            } else {
                // Restart the ADM
                try audioDeviceModule.setRecording(false)
                try audioDeviceModule.setRecording(true)
            }
        }

        /// Starts or stops ADM recording when `shouldRecord` changes.
        private func didSetShouldRecord(
            _ value: Bool,
            state: RTCAudioStore.StoreState,
            audioDeviceModule: AudioDeviceModule
        ) throws {
            guard audioDeviceModule.isRecording != value else {
                return
            }

            try audioDeviceModule.setRecording(value)
        }

        /// Applies the store's microphone muted state to the ADM.
        private func didSetMicrophoneMuted(
            _ value: Bool,
            state: RTCAudioStore.StoreState,
            audioDeviceModule: AudioDeviceModule
        ) throws {
            guard
                state.shouldRecord
            else {
                return
            }

            try audioDeviceModule.setMuted(value)
        }

        /// Handles ADM swapping by wiring up observers and ensuring the previous
        /// module is stopped.
        private func didSetAudioDeviceModule(
            _ audioDeviceModule: AudioDeviceModule?,
            state: RTCAudioStore.StoreState
        ) throws {
            try state.audioDeviceModule?.setRecording(false)

            disposableBag.removeAll()

            guard let audioDeviceModule else {
                return
            }

            audioDeviceModule
                .isRecordingPublisher
                .removeDuplicates()
                .sink { [weak self] in self?.dispatcher?.dispatch(.setRecording($0)) }
                .store(in: disposableBag)

            audioDeviceModule
                .isMicrophoneMutedPublisher
                .removeDuplicates()
                .log(.debug) { "ADM sent isMicrophoneMuted:\($0)." }
                .sink { [weak self] in self?.dispatcher?.dispatch(.setMicrophoneMuted($0)) }
                .store(in: disposableBag)
        }
    }
}
