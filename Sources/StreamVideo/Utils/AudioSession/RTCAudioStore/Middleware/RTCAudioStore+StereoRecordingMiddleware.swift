//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation

extension RTCAudioStore {

    final class StereoRecordingMiddleware: @unchecked Sendable, RTCAudioStoreMiddleware {
        @Injected(\.orientationAdapter) private var orientationAdapter

        private weak var store: RTCAudioStore?
        private let audioSession: AVAudioSessionProtocol?
        private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)
        private var isActivated = false

        init(_ store: RTCAudioStore) {
            self.store = store
            self.audioSession = store.session.avSession
        }

        func apply(
            state: RTCAudioStore.State,
            action: RTCAudioStoreAction,
            file: StaticString,
            function: StaticString,
            line: UInt
        ) {
            guard case let .audioSession(audioSessionAction) = action else {
                return
            }

            switch audioSessionAction {
            case .setStereoRecording(let isEnabled):
                processingQueue.addTaskOperation { [weak self] in
                    guard let self else {
                        return
                    }
                    isEnabled ? await activate() : await deactivate()
                }
            default:
                break
            }
        }

        // MARK: - Private Helpers

        private func activate() async {
            guard !isActivated, let audioSession else {
                isActivated = false
                return
            }

            do {
                try await store?.dispatchAsync(.audioSession(.setOverrideOutputPort(.none)))
                try audioSession.enableBuiltInMic()
                try audioSession.setStereoAudioPosition(
                    .front,
                    deviceOrientation: orientationAdapter.orientation
                )
                try await store?.restartAudioSessionSync()
                isActivated = true
                log.debug("Stereo recording has been activated.", subsystems: .audioSession)
            } catch {
                log.error(error, subsystems: .audioSession)
            }
        }

        private func deactivate() async {
            guard isActivated else {
                return
            }

            do {
                try audioSession?.resetInputPreferences()
                try await store?.restartAudioSessionSync()
                log.debug("Stereo recording has been deactivated.", subsystems: .audioSession)
            } catch {
                log.error(error, subsystems: .audioSession)
            }

            isActivated = false
        }
    }
}
