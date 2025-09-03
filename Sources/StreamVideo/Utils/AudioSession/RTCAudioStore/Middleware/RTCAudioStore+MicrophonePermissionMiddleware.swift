//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension RTCAudioStore {

    final class MicrophonePermissionMiddleware: RTCAudioStoreMiddleware {

        weak var store: RTCAudioStore?

        init(_ store: RTCAudioStore) {
            self.store = store
        }

        func apply(
            state: RTCAudioStore.State,
            action: RTCAudioStoreAction,
            file: StaticString,
            function: StaticString,
            line: UInt
        ) {
            guard
                case let .audioSession(audioSessionAction) = action
            else {
                return
            }

            switch audioSessionAction {
            case let .setHasRecordingPermission(value) where value && state.isActive:
                guard let store else {
                    return
                }
                store.restartAudioSession(
                    category: store.state.category,
                    mode: store.state.mode,
                    options: store.state.options
                )
            default:
                break
            }
        }
    }
}
