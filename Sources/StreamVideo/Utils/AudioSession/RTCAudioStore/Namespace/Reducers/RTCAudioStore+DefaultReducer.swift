//
//  RTCAudioStore+DefaultReducer.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 9/10/25.
//

import Foundation
import StreamWebRTC

extension RTCAudioStore.Namespace {

    final class DefaultReducer: Reducer<RTCAudioStore.Namespace>, @unchecked Sendable {

        private let source: RTCAudioSession

        init(_ source: RTCAudioSession) {
            self.source = source
            super.init()
        }

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
                    source.lockForConfiguration()
                    defer { source.unlockForConfiguration() }
                    try source.setActive(value)
                    try source.avSession.setIsActive(value)
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

            case let .setPrefersHiFiPlayback(value):
                updatedState.prefersHiFiPlayback = value

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

            case .streamVideo:
                break
            }

            return updatedState
        }
    }
}

