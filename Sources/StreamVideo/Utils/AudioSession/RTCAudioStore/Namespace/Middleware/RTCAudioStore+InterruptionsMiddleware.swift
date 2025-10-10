//
//  RTCAudioStore+InterruptionsMiddleware.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 9/10/25.
//

import Foundation
import AVFoundation
import StreamWebRTC

extension RTCAudioStore {

    final class InterruptionsMiddleware: Middleware<RTCAudioStore.Namespace>, @unchecked Sendable {

        private let audioSessionObserver: RTCAudioSessionPublisher
        private let disposableBag = DisposableBag()

        init(_ source: RTCAudioSession) {
            self.audioSessionObserver = .init(source)
            super.init()

            audioSessionObserver
                .publisher
                .sink { [weak self] in self?.handle($0) }
                .store(in: disposableBag)
        }

        // MARK: - Private Helpers

        private func handle(
            _ event: RTCAudioSessionPublisher.Event
        ) {
            switch event {
            case .didBeginInterruption:
                dispatcher?.dispatch(.setInterrupted(true))

            case .didEndInterruption(let shouldResumeSession):
                var actions: [Namespace.Action] = [
                    .setInterrupted(false)
                ]

                if
                    shouldResumeSession,
                    let state = stateProvider?(),
                    state.audioDeviceModule != nil
                {
                    let isRecording = state.isRecording
                    let isMicrophoneMuted = state.isMicrophoneMuted


                    if isRecording {
                        actions.append(.setRecording(false))
                        actions.append(.setRecording(true))
                    }

                    actions.append(.setMicrophoneMuted(isMicrophoneMuted))

                }
                dispatcher?.dispatch(actions.map(\.box))

            case .didChangeRoute:
                break
            }
        }
    }
}

