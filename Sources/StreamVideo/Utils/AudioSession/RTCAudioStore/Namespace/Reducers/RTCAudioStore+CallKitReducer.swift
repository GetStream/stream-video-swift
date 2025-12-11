//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

extension RTCAudioStore.Namespace {

    /// Updates store state in response to CallKit activation events so it stays
    /// aligned with `RTCAudioSession`.
    final class CallKitReducer: Reducer<RTCAudioStore.Namespace>, @unchecked Sendable {

        private let source: AudioSessionProtocol

        init(_ source: AudioSessionProtocol) {
            self.source = source
        }

        /// Applies CallKit actions by forwarding the callbacks to the WebRTC
        /// session and returning the updated activity flag.
        override func reduce(
            state: State,
            action: Action,
            file: StaticString,
            function: StaticString,
            line: UInt
        ) async throws -> State {
            guard case let .callKit(action) = action else {
                return state
            }

            var updatedState = state

            switch action {
            case let .activate(audioSession):
                source.audioSessionDidActivate(audioSession)
                updatedState.isActive = source.isActive

            case let .deactivate(audioSession):
                source.audioSessionDidDeactivate(audioSession)
                updatedState.isActive = source.isActive
            }

            return updatedState
        }
    }
}
