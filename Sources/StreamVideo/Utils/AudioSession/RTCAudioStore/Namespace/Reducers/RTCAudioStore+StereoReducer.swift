//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

extension RTCAudioStore.Namespace {

    /// Updates store state in response to CallKit activation events so it stays
    /// aligned with `RTCAudioSession`.
    final class StereoReducer: Reducer<RTCAudioStore.Namespace>, @unchecked Sendable {

        /// Applies CallKit actions by forwarding the callbacks to the WebRTC
        /// session and returning the updated activity flag.
        override func reduce(
            state: State,
            action: Action,
            file: StaticString,
            function: StaticString,
            line: UInt
        ) async throws -> State {
            guard case let .stereo(action) = action else {
                return state
            }

            var updatedState = state

            switch action {
            case let .setPlayoutAvailable(value):
                updatedState.stereo.playoutAvailable = value

            case let .setPlayoutEnabled(value):
                updatedState.stereo.playoutEnabled = value
            }

            return updatedState
        }
    }
}
