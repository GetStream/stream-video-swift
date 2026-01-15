//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
import StreamWebRTC

extension RTCAudioStore {

    /// Converts audio session interruption callbacks into store actions so the
    /// audio pipeline can gracefully pause and resume.
    final class InterruptionsEffect: StoreEffect<RTCAudioStore.Namespace>, @unchecked Sendable {

        private let audioSessionObserver: RTCAudioSessionPublisher
        private let disposableBag = DisposableBag()

        convenience init(_ source: RTCAudioSession) {
            self.init(.init(source))
        }

        init(_ audioSessionObserver: RTCAudioSessionPublisher) {
            self.audioSessionObserver = audioSessionObserver
            super.init()

            audioSessionObserver
                .publisher
                .sink { [weak self] in self?.handle($0) }
                .store(in: disposableBag)
        }

        // MARK: - Private Helpers

        /// Handles the underlying audio session events and dispatches the
        /// appropriate store actions.
        private func handle(
            _ event: RTCAudioSessionPublisher.Event
        ) {
            switch event {
            case .didBeginInterruption:
                dispatcher?.dispatch(.setInterrupted(true))

            case .didEndInterruption(let shouldResumeSession):
                guard
                    state?.isInterrupted == true
                else {
                    return
                }

                var actions: [Namespace.Action] = [
                    .setInterrupted(false)
                ]

                if
                    shouldResumeSession,
                    let state = stateProvider?(),
                    state.audioDeviceModule != nil {
                    let isRecording = state.isRecording
                    let isMicrophoneMuted = state.isMicrophoneMuted

                    if isRecording {
                        actions.append(.setRecording(false))
                        actions.append(.setRecording(true))
                    }

                    actions.append(.setMicrophoneMuted(isMicrophoneMuted))
                }
                dispatcher?.dispatch(actions.map(\.box))
            default:
                break
            }
        }
    }
}
