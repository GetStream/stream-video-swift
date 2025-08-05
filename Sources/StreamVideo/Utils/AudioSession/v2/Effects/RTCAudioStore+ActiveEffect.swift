//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

extension RTCAudioStore {

    final class ActiveEffect: NSObject, RTCAudioSessionDelegate {

        private let session: RTCAudioSession
        private weak var store: RTCAudioStore?

        init(_ store: RTCAudioStore) {
            session = store.session
            self.store = store
            super.init()

            session.add(self)
        }

        deinit {
            session.remove(self)
        }

        // MARK: - RTCAudioSessionDelegate

        func audioSession(
            _ audioSession: RTCAudioSession,
            didSetActive active: Bool
        ) {
            guard
                let state = store?.state,
                state.isActive != active || state.isAudioEnabled != active
            else {
                return
            }

            store?.dispatch(.rtc(.isActive(active)))
            store?.dispatch(.rtc(.isAudioEnabled(active)))
        }
    }
}
