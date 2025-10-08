//
//  RTCAudioStore+RouteChangeMiddleware.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 9/10/25.
//

import Foundation
import AVFoundation
import StreamWebRTC

extension RTCAudioStore {

    final class RouteChangeMiddleware: Middleware<RTCAudioStore.Namespace>, @unchecked Sendable {

        private let audioSessionObserver: RTCAudioSessionPublisher
        private let disposableBag = DisposableBag()

        init(_ source: RTCAudioSession) {
            self.audioSessionObserver = .init(source)
            super.init()

            audioSessionObserver
                .publisher
                .compactMap {
                    guard
                        case let .didChangeRoute(reason, from, to) = $0
                    else {
                        return nil
                    }
                    return (reason, from, to)
                }
                .sink { [weak self] in self?.didChangeRoute(reason: $0, from: $1, to: $2) }
                .store(in: disposableBag)
        }

        // MARK: - Private Helpers
        
        private func didChangeRoute(
            reason: AVAudioSession.RouteChangeReason,
            from: AVAudioSessionRouteDescription,
            to: AVAudioSessionRouteDescription
        ) {
            let currentRoute = StoreState.AudioRoute(to)
            let previousRoute = StoreState.AudioRoute(from)
            dispatcher?.dispatch([
                .normal(.setCurrentRoute(currentRoute)),
                .normal(.avAudioSession(.setOverrideOutputAudioPort(currentRoute.isSpeaker ? .speaker : .none)))
            ])
            log.debug(
                "AudioSession route changed from \(previousRoute) to \(currentRoute) due to:\(reason)",
                subsystems: .audioSession
            )
        }
    }
}
