//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

extension RTCAudioStore {

    /// Namespace that defines the store configuration for permission
    /// management.
    public enum Namespace: StoreNamespace {
        public typealias State = StoreState

        typealias Action = StoreAction

        static let identifier: String = "io.getstream.audio.store"

        static func reducers(audioSession: RTCAudioSession) -> [Reducer<RTCAudioStore.Namespace>] {
            [
                DefaultReducer(audioSession),
                AVAudioSessionReducer(audioSession),
                WebRTCAudioSessionReducer(audioSession),
                CallKitReducer(audioSession),
                StereoReducer()
            ]
        }

        static func middleware(audioSession: RTCAudioSession) -> [Middleware<RTCAudioStore.Namespace>] {
            [
                InterruptionsMiddleware(audioSession),
                RouteChangeMiddleware(audioSession),
                AudioDeviceModuleMiddleware(),
//                ActiveCallMiddleware(),
                HiFiMiddleware()
            ]
        }

        static func coordinator() -> StoreCoordinator<RTCAudioStore.Namespace> {
            Coordinator()
        }
    }
}
