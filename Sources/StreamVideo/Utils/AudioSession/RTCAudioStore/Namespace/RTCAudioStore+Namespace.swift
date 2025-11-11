//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

extension RTCAudioStore {

    /// Namespace that defines the store configuration for permission
    /// management.
    enum Namespace: StoreNamespace {
        typealias State = StoreState

        typealias Action = StoreAction

        static let identifier: String = "io.getstream.audio.store"

        static func reducers(audioSession: RTCAudioSession) -> [Reducer<RTCAudioStore.Namespace>] {
            [
                DefaultReducer(audioSession),
                AVAudioSessionReducer(audioSession),
                WebRTCAudioSessionReducer(audioSession),
                CallKitReducer(audioSession)
            ]
        }

        static func middleware(audioSession: RTCAudioSession) -> [Middleware<RTCAudioStore.Namespace>] {
            [
                InterruptionsMiddleware(audioSession),
                AudioDeviceModuleMiddleware()
            ]
        }

        static func effects(audioSession: RTCAudioSession) -> Set<StoreEffect<RTCAudioStore.Namespace>> {
            [
                StereoPlayoutEffect(),
                RouteChangeEffect(audioSession)
            ]
        }

        static func logger() -> StoreLogger<RTCAudioStore.Namespace> {
            .init(logSkipped: true)
        }

        static func coordinator() -> StoreCoordinator<RTCAudioStore.Namespace> {
            Coordinator()
        }
    }
}
