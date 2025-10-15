//
//  RTCAudioStore+Namespace.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 9/10/25.
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
                RouteChangeMiddleware(audioSession),
                AudioDeviceModuleMiddleware(),
                ActiveCallMiddleware(),
                HiFiMiddleware()
            ]
        }

        static func coordinator() -> StoreCoordinator<RTCAudioStore.Namespace> {
            Coordinator()
        }
    }
}
