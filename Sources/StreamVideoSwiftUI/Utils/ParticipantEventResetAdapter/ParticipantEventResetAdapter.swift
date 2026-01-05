//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo

final class ParticipantEventResetAdapter: @unchecked Sendable {

    private var observationCancellable: AnyCancellable?
    private weak var viewModel: CallViewModel?
    private let processingQueue = UnfairQueue()
    private let interval: TimeInterval

    private var timerCancellable: AnyCancellable?
    private var lastEventReceivedAt: Date?

    init(
        _ viewModel: CallViewModel,
        interval: TimeInterval = 2
    ) {
        self.viewModel = viewModel
        self.interval = interval
        Task { @MainActor [weak self] in
            guard let self else { return }
            observationCancellable = viewModel
                .$participantEvent
                .sink { [weak self] in self?.execute($0) }
        }
    }

    private func execute(_ event: ParticipantEvent?) {
        processingQueue.sync {
            guard event != nil else {
                timerCancellable?.cancel()
                timerCancellable = nil
                lastEventReceivedAt = nil
                return
            }

            lastEventReceivedAt = Date()

            guard timerCancellable == nil else {
                return
            }

            timerCancellable = DefaultTimer
                .publish(every: 1)
                .sink { [weak self] _ in self?.timerFired() }
        }
    }

    private func timerFired() {
        processingQueue.sync {
            guard
                let lastEventReceivedAt,
                Date().timeIntervalSince(lastEventReceivedAt) >= interval
            else {
                return
            }

            Task { @MainActor in
                viewModel?.participantEvent = nil
            }
        }
    }
}
