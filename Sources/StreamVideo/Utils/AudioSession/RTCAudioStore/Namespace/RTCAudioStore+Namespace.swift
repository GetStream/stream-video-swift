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
                CallKitReducer(audioSession),
                StereoPlayoutAvailabilityReducer() // This needs to be after the AVAudioSessionReducer
            ]
        }

        static func middleware(audioSession: RTCAudioSession) -> [Middleware<RTCAudioStore.Namespace>] {
            [
                InterruptionsMiddleware(audioSession),
                RouteChangeMiddleware(audioSession),
                AudioDeviceModuleMiddleware()
            ]
        }

        static func effects(audioSession: RTCAudioSession) -> Set<StoreEffect<RTCAudioStore.Namespace>> {
            [
                StereoPlayoutEffect()
            ]
        }

        static func logger() -> StoreLogger<RTCAudioStore.Namespace> {
            .init(logSkipped: false)
        }

        static func coordinator() -> StoreCoordinator<RTCAudioStore.Namespace> {
            Coordinator()
        }
    }
}
