//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

/// Applies the selected `AudioFilter` to incoming capture buffers and keeps it
/// configured with the current sample format.

extension AudioProcessingStore.Namespace {

    final class AudioFilterMiddleware: Middleware<AudioProcessingStore.Namespace>, @unchecked Sendable {

        private var cancellable: AnyCancellable?

        override func apply(
            state: AudioProcessingStore.Namespace.StoreState,
            action: AudioProcessingStore.Namespace.StoreAction,
            file: StaticString,
            function: StaticString,
            line: UInt
        ) {
            switch action {
            case let .setInitializedConfiguration(sampleRate, channels):
                // Initialize the filter with the negotiated format.
                if let audioFilter = state.audioFilter {
                    audioFilter.initialize(
                        sampleRate: sampleRate,
                        channels: channels
                    )
                }
            case let .setAudioFilter(audioFilter):
                state.audioFilter?.release()
                // Late filter selection: initialize if we already know format.
                if state.initializedSampleRate > 0, state.initializedChannels > 0 {
                    audioFilter?.initialize(
                        sampleRate: state.initializedSampleRate,
                        channels: state.initializedChannels
                    )
                }
                didUpdate(
                    audioFilter,
                    capturePostProcessingDelegate: state.capturePostProcessingDelegate
                )

            case .release:
                state.audioFilter?.release()
            default:
                break
            }
        }

        // MARK: - Private Helpers

        private func didUpdate(
            _ audioFilter: AudioFilter?,
            capturePostProcessingDelegate: AudioCustomProcessingModule
        ) {
            cancellable?.cancel()
            cancellable = nil

            guard let audioFilter else {
                return
            }

            cancellable = capturePostProcessingDelegate
                .publisher
                .compactMap {
                    guard case let .audioProcessingProcess(buffer) = $0 else {
                        return nil
                    }
                    return buffer
                }
                .sink { [weak self, audioFilter] in self?.process($0, on: audioFilter) }
        }

        private func process(
            _ audioBuffer: RTCAudioBuffer,
            on audioFilter: AudioFilter
        ) {
            var audioBuffer = audioBuffer
            audioFilter.applyEffect(to: &audioBuffer)
        }
    }
}
