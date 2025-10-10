//
//  RTCAudioStore+WebRTCAudioSessionReducer.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 9/10/25.
//

import Foundation
import StreamWebRTC

extension RTCAudioStore.Namespace {

    final class WebRTCAudioSessionReducer: Reducer<RTCAudioStore.Namespace>, @unchecked Sendable {

        private let source: RTCAudioSession

        init(_ source: RTCAudioSession) {
            self.source = source
        }

        override func reduce(
            state: State,
            action: Action,
            file: StaticString,
            function: StaticString,
            line: UInt
        ) throws -> State {
            guard case let .webRTCAudioSession(action) = action else {
                return state
            }

            var updatedState = state

            switch action {
            case let .setAudioEnabled(value):
                source.isAudioEnabled = value
                updatedState.webRTCAudioSessionConfiguration.isAudioEnabled = value

            case let .setUseManualAudio(value):
                source.useManualAudio = value
                updatedState.webRTCAudioSessionConfiguration.useManualAudio = value

            case let .setPrefersNoInterruptionsFromSystemAlerts(value):
                if #available(iOS 14.5, *) {
                    try source.setPrefersNoInterruptionsFromSystemAlerts(value)
                    updatedState.webRTCAudioSessionConfiguration.prefersNoInterruptionsFromSystemAlerts = value
                }
            }

            return updatedState
        }
    }
}


