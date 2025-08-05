//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

extension RTCAudioStore {

    final class InterruptionEffect: NSObject, RTCAudioSessionDelegate {

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

        func audioSessionDidBeginInterruption(_ session: RTCAudioSession) {
            store?.dispatch(.rtc(.isInterrupted(true)))
            store?.dispatch(.rtc(.isAudioEnabled(false)))
        }

        func audioSessionDidEndInterruption(
            _ session: RTCAudioSession,
            shouldResumeSession: Bool
        ) {
            guard let store else {
                return
            }

            store.dispatch(.rtc(.isInterrupted(false)))
            if shouldResumeSession {
                store.dispatch(.rtc(.isActive(false)))
                store.dispatch(.rtc(.isAudioEnabled(false)))

                store.dispatch(.store(.delay(seconds: 0.2)))

                store.dispatch(
                    .rtc(
                        .setCategory(
                            store.state.category,
                            mode: store.state.mode,
                            options: store.state.options
                        )
                    )
                )

                store.dispatch(.store(.delay(seconds: 0.2)))

                store.dispatch(.rtc(.isAudioEnabled(true)))
                store.dispatch(.rtc(.isActive(true)))
            }
        }
    }
}
