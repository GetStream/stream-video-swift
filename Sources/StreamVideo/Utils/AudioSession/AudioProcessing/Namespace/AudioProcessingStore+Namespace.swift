//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Namespace describing reducers, middleware and identity for the store that
/// powers `AudioProcessingStore`.

extension AudioProcessingStore {

    enum Namespace: StoreNamespace {
        typealias State = StoreState

        typealias Action = StoreAction

        /// Unique id used for debugging and instrumentation.
        static let identifier: String = "io.getstream.audio.processing.store"

        /// Reducers applied in order to transition state.
        static func reducers() -> [Reducer<AudioProcessingStore.Namespace>] {
            [
                DefaultReducer()
            ]
        }

        /// Middleware that observes WebRTC callbacks and applies filters.
        static func middleware() -> [Middleware<AudioProcessingStore.Namespace>] {
            [
                CapturedChannelsMiddleware(),
                AudioFilterMiddleware()
            ]
        }
    }
}
