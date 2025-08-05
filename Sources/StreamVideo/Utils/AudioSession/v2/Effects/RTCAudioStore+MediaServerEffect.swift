//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

extension RTCAudioStore {

    final class MediaServerEffect: NSObject, RTCAudioSessionDelegate {

        private let session: RTCAudioSession
        private let requiresRejoinSubject: PassthroughSubject<Bool, Never>
        private weak var store: RTCAudioStore?

        init(
            _ store: RTCAudioStore,
            requiresRejoinSubject: PassthroughSubject<Bool, Never>
        ) {
            session = store.session
            self.store = store
            self.requiresRejoinSubject = requiresRejoinSubject
            super.init()

            session.add(self)
        }

        deinit {
            session.remove(self)
        }

        // MARK: - RTCAudioSessionDelegate

        func audioSessionMediaServerReset(_ session: RTCAudioSession) {
            requiresRejoinSubject.send(true)
        }

        func audioSessionMediaServerTerminated(_ session: RTCAudioSession) {
            requiresRejoinSubject.send(true)
        }

        func audioSession(
            _ audioSession: RTCAudioSession,
            audioUnitStartFailedWithError error: any Error
        ) {
            requiresRejoinSubject.send(true)
        }

        func audioSession(
            _ audioSession: RTCAudioSession,
            didDetectPlayoutGlitch totalNumberOfGlitches: Int64
        ) {
//            guard totalNumberOfGlitches > 3 else {
//                return
//            }
//            requiresRejoinSubject.send(true)
        }
    }
}
