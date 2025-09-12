//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension AudioProcessingStore.Namespace {

    final class CapturedChannelsMiddleware: Middleware<AudioProcessingStore.Namespace>, @unchecked Sendable {

        private var cancellable: AnyCancellable?

        override func apply(
            state: AudioProcessingStore.Namespace.StoreState,
            action: AudioProcessingStore.Namespace.StoreAction,
            file: StaticString,
            function: StaticString,
            line: UInt
        ) {
            switch action {
            case .load:
                cancellable = state
                    .capturePostProcessingDelegate
                    .publisher
                    .sink { [weak self] in self?.didReceiveProcessingEvent($0) }
                
            default:
                break
            }
        }

        // MARK: - Private Helpers

        private func didReceiveProcessingEvent(
            _ event: AudioCustomProcessingModule.Event
        ) {
            switch event {
            case let .audioProcessingInitialize(sampleRateHz, channels):
                dispatcher?.dispatch(
                    .setInitializedConfiguration(
                        sampleRate: sampleRateHz,
                        channels: channels
                    )
                )
            case let .audioProcessingProcess(buffer):
                if buffer.channels != stateProvider?()?.numberOfCaptureChannels {
                    dispatcher?.dispatch(.setNumberOfCaptureChannels(buffer.channels))
                }
            case .audioProcessingRelease:
                dispatcher?.dispatch(.release)
            }
        }
    }
}
