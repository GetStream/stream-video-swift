//
//  RTCAudioStore+HiFiMiddleware.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 14/10/25.
//

import Foundation
import AVFoundation
import StreamWebRTC
import Combine

extension RTCAudioStore {

    final class HiFiMiddleware: Middleware<RTCAudioStore.Namespace>, @unchecked Sendable {

        private var isStereoAvailableCancellable: AnyCancellable?

        override func apply(
            state: RTCAudioStore.StoreState,
            action: RTCAudioStore.StoreAction,
            file: StaticString,
            function: StaticString,
            line: UInt
        ) {
            switch action {
            case let .setAudioDeviceModule(value):
                isStereoAvailableCancellable?.cancel()
                isStereoAvailableCancellable = nil

                if let value {
                    isStereoAvailableCancellable = value
                        .isStereoPlayoutAvailablePublisher
                        .sink { [weak self] in self?.didUpdateStereoAvailability($0) }
                }

            case .setCurrentRoute:
                didUpdateStereoAvailability(state.audioDeviceModule?.isStereoPlayoutAvailable ?? false)

            case let .setPrefersHiFiPlayback(value):
                if let audioDeviceModule = state.audioDeviceModule {
                    setStereoPlayoutEnabled(
                        value,
                        audioDeviceModule: audioDeviceModule
                    )
                }
            default:
                break
            }
        }

        // MARK: - Private Helpers

        private func setStereoPlayoutEnabled(
            _ isEnabled: Bool,
            audioDeviceModule: AudioDeviceModule,
            file: StaticString = #file,
            function: StaticString = #function,
            line: UInt = #line
        ) {
            do {
                try audioDeviceModule.setStereoPlayoutEnabled(
                    isEnabled && audioDeviceModule.isStereoPlayoutAvailable,
                    file: file,
                    function: function,
                    line: line
                )
                log.debug(
                    "Completed setStereoPlayoutEnabled:\(isEnabled) on audioDeviceModule:\(audioDeviceModule).",
                    subsystems: .audioSession,
                    functionName: function,
                    fileName: file,
                    lineNumber: line
                )
            } catch {
                log.error(
                    error,
                    subsystems: .audioSession,
                    functionName: function,
                    fileName: file,
                    lineNumber: line
                )
            }
        }

        private func didUpdateStereoAvailability(
            _ isAvailable: Bool
        ) {
            guard
                let state = stateProvider?(),
                let audioDeviceModule = state.audioDeviceModule
            else {
                return
            }

            setStereoPlayoutEnabled(
                isAvailable && state.prefersHiFiPlayback,
                audioDeviceModule: audioDeviceModule
            )
        }
    }
}

