//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension Moderation {

    /// Moderates outgoing video by applying policies to an active call.
    final class VideoAdapter: @unchecked Sendable {

        @Atomic private(set) var isActive = false
        private(set) var unmoderatedVideoFilter: VideoFilter?
        private(set) var policy: VideoPolicy

        private weak var call: Call?

        private let disposableBag = DisposableBag()
        private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)
        private let timerCancellableKey = UUID().uuidString

        init(
            _ call: Call,
            policy: VideoPolicy = .init(
                duration: 20,
                videoFilter: .blur
            )
        ) {
            self.policy = policy
            self.call = call

            call
                .eventPublisher(for: CallModerationBlurEvent.self)
                .receive(on: processingQueue)
                .sink { [weak self] in self?.process($0) }
                .store(in: disposableBag)
        }

        // MARK: - Configuration

        /// Stores the last user-selected filter so it can be restored after
        /// moderation finishes.
        func didUpdateVideoFilter(_ videoFilter: VideoFilter?) {
            processingQueue.addOperation { [weak self] in
                if videoFilter?.id != self?.policy.videoFilter.id {
                    self?.unmoderatedVideoFilter = videoFilter
                }
            }
        }

        /// Updates the moderation policy applied to future events.
        func didUpdateFilterPolicy(_ policy: VideoPolicy) {
            processingQueue.addOperation { [weak self] in
                self?.policy = policy
            }
        }

        // MARK: - Private Helpers

        /// Activates moderation once the backend requests a blur event.
        private func process(_ event: CallModerationBlurEvent) {
            disposableBag.remove(timerCancellableKey)
            call?.setVideoFilter(policy.videoFilter)

            isActive = true

            if policy.duration > 0 {
                DefaultTimer
                    .publish(every: policy.duration)
                    .receive(on: processingQueue)
                    .sink { [weak self] _ in self?.deactivate() }
                    .store(in: disposableBag, key: timerCancellableKey)
            }
        }

        /// Deactivates moderation and restores the previous filter if needed.
        private func deactivate() {
            guard isActive else {
                return
            }

            disposableBag.remove(timerCancellableKey)
            // Restore any filter we had before moderation
            call?.setVideoFilter(unmoderatedVideoFilter)

            isActive = false
        }
    }
}
