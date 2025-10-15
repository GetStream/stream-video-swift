//
//  RTCAudioStore+ActiveCallMiddleware.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 14/10/25.
//

import Foundation
import AVFoundation
import StreamWebRTC
import Combine

extension RTCAudioStore {

    final class ActiveCallMiddleware: Middleware<RTCAudioStore.Namespace>, @unchecked Sendable {

        private var activeCallSettingsCancellable: AnyCancellable?
        private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)

        // MARK: - Middleware

        override func apply(
            state: RTCAudioStore.StoreState,
            action: RTCAudioStore.StoreAction,
            file: StaticString,
            function: StaticString,
            line: UInt
        ) {
            guard
                case let .streamVideo(action) = action
            else {
                return
            }

            switch action {
            case .setActiveCall(let call):
                processingQueue.addTaskOperation { @MainActor [weak self] in
                    self?.didUpdate(call)
                }
            }
        }

        // MARK: - Private Helpers

        @MainActor
        private func didUpdate(_ call: Call?) {
            activeCallSettingsCancellable?.cancel()
            activeCallSettingsCancellable = nil

            guard let call else {
                dispatcher?.dispatch(.setPrefersHiFiPlayback(false))
                return
            }

            activeCallSettingsCancellable = call
                .state
                .$settings
                .compactMap { $0?.audio.hifiAudioEnabled ?? false }
                .removeDuplicates()
                .sink { [weak self] in self?.dispatcher?.dispatch(.setPrefersHiFiPlayback($0)) }
        }
    }
}


