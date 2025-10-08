//
//  RTCAudioStore+AudioDeviceModuleMiddleware.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 9/10/25.
//

import Foundation
import AVFoundation
import StreamWebRTC

extension RTCAudioStore {

    final class AudioDeviceModuleMiddleware: Middleware<RTCAudioStore.Namespace>, @unchecked Sendable {

        private let disposableBag = DisposableBag()

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
                didSetInterrupted(
                    value,
                    state: state,
                    audioDeviceModule: audioDeviceModule
                )

            case let .setShouldRecord(value):
                didSetShouldRecord(
                    value,
                    state: state,
                    audioDeviceModule: audioDeviceModule
                )

            case let .setMicrophoneMuted(value):
                didSetMicrophoneMuted(
                    value,
                    state: state,
                    audioDeviceModule: audioDeviceModule
                )

            case let .setAudioDeviceModule(value):
                didSetAudioDeviceModule(
                    value,
                    state: state
                )

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

        private func didSetInterrupted(
            _ value: Bool,
            state: RTCAudioStore.StoreState,
            audioDeviceModule: AudioDeviceModule
        ) {
            guard
                state.isActive,
                state.shouldRecord
            else {
                return
            }

            if value {
                audioDeviceModule.setRecording(false)
            } else {
                // Restart the ADM
                audioDeviceModule.setRecording(false)
                audioDeviceModule.setRecording(true)
            }
        }

        private func didSetShouldRecord(
            _ value: Bool,
            state: RTCAudioStore.StoreState,
            audioDeviceModule: AudioDeviceModule
        ) {
            guard audioDeviceModule.isRecording != value else {
                return
            }

            audioDeviceModule.setRecording(value)
        }

        private func didSetMicrophoneMuted(
            _ value: Bool,
            state: RTCAudioStore.StoreState,
            audioDeviceModule: AudioDeviceModule
        ) {
            guard
                state.shouldRecord
            else {
                return
            }

            audioDeviceModule.setMuted(value)
        }

        private func didSetAudioDeviceModule(
            _ audioDeviceModule: AudioDeviceModule?,
            state: RTCAudioStore.StoreState
        ) {
            state.audioDeviceModule?.setRecording(false)

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


