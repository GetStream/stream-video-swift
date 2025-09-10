//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension LocalAudioMediaAdapter {

    enum Namespace: StoreNamespace {
        typealias State = StoreState

        typealias Action = StoreAction

        static let identifier: String = "io.getstream.local.audio.store"

        static func reducers() -> [Reducer<LocalAudioMediaAdapter.Namespace>] {
            [
                DefaultReducer()
            ]
        }

        static func middleware() -> [Middleware<LocalAudioMediaAdapter.Namespace>] {
            [
                IdleMiddleware(),
                TrackRegisterMiddleware(),
                SFUMiddleware(),
                TransceiverMiddleware(),
                AudioBitrateMiddleware()
            ]
        }
    }
}
