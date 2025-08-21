//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

extension LocalAudioMediaAdapter.Namespace {

    final class AudioBitrateMiddleware: Middleware<LocalAudioMediaAdapter.Namespace>, @unchecked Sendable {

        @Injected(\.audioStore) private var audioStore

        private var audioStoreCancellable: AnyCancellable?

        override init() {
            super.init()

            audioStoreCancellable = audioStore
                .publisher(\.inputConfiguration.audioBitrate)
                .removeDuplicates()
                .sink { [weak self] in self?.didUpdate($0) }
        }

        override func apply(
            state: LocalAudioMediaAdapter.Namespace.StoreState,
            action: LocalAudioMediaAdapter.Namespace.StoreAction,
            file: StaticString,
            function: StaticString,
            line: UInt
        ) async {
            /* No-op */
        }

        // MARK: - Private Helpers

        private func didUpdate(_ audioBitrate: AudioBitrate) {
            dispatcher?.dispatch(
                .setAudioBitrateAndMediaConstraints(
                    audioBitrate: audioBitrate,
                    mediaConstraints: audioBitrate == .musicHighQuality ? .hiFiAudioConstraints : .defaultConstraints
                )
            )
        }
    }
}
