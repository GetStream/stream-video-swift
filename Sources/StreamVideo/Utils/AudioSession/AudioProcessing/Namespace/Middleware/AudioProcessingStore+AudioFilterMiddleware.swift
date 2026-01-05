//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

/// Applies the selected `AudioFilter` to incoming capture buffers and keeps it
/// configured with the current sample format.

extension AudioProcessingStore.Namespace {

    final class AudioFilterMiddleware: Middleware<AudioProcessingStore.Namespace>, @unchecked Sendable {

        @Injected(\.audioStore) private var audioStore

        private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)
        private var currentRouteCancellable: AnyCancellable?

        override init() {
            super.init()
            /// For some reason AudioFilters stop working after the audioOutput changes a couple of
            /// times. Here we reapply the existing filter if any to ensure correct configuration
            currentRouteCancellable = audioStore
                .publisher(\.currentRoute)
                .removeDuplicates()
                .receive(on: processingQueue)
                .sink { [weak self] _ in self?.reApplyFilterAfterRouteChange() }
        }

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
                processingQueue.addOperation { [weak self] in
                    guard let self else { return }
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
                }

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
            capturePostProcessingDelegate.processingHandler = nil

            guard let audioFilter else {
                return
            }

            capturePostProcessingDelegate.processingHandler = { [weak self] in
                self?.process($0, on: audioFilter)
            }
        }

        private func process(
            _ audioBuffer: RTCAudioBuffer,
            on audioFilter: AudioFilter
        ) {
            var audioBuffer = audioBuffer
            audioFilter.applyEffect(to: &audioBuffer)
        }

        private func reApplyFilterAfterRouteChange() {
            processingQueue.addOperation { [weak self] in
                guard
                    let self,
                    let audioFilter = state?.audioFilter,
                    let capturePostProcessingDelegate = state?.capturePostProcessingDelegate
                else {
                    return
                }

                didUpdate(nil, capturePostProcessingDelegate: capturePostProcessingDelegate)
                didUpdate(audioFilter, capturePostProcessingDelegate: capturePostProcessingDelegate)
            }
        }
    }
}
