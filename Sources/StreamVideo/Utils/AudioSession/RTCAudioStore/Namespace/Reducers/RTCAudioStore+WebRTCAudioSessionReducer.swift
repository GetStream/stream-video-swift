//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

extension RTCAudioStore.Namespace {

    /// Synchronises WebRTC-specific knobs (manual audio, interruptions) with
    /// the underlying session.
    final class WebRTCAudioSessionReducer: Reducer<RTCAudioStore.Namespace>, @unchecked Sendable {

        private let source: AudioSessionProtocol

        init(_ source: AudioSessionProtocol) {
            self.source = source
        }

        /// Applies `.webRTCAudioSession` actions to both the store and the
        /// WebRTC session instance.
        override func reduce(
            state: State,
            action: Action,
            file: StaticString,
            function: StaticString,
            line: UInt
        ) async throws -> State {
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
