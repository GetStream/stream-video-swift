//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension AudioProcessingStore {

    enum Namespace: StoreNamespace {
        typealias State = StoreState

        typealias Action = StoreAction

        static let identifier: String = "io.getstream.audio.processing.store"

        static func reducers() -> [Reducer<AudioProcessingStore.Namespace>] {
            [
                DefaultReducer()
            ]
        }

        static func middleware() -> [Middleware<AudioProcessingStore.Namespace>] {
            [
                CapturedChannelsMiddleware(),
                AudioFilterMiddleware()
            ]
        }
    }
}
