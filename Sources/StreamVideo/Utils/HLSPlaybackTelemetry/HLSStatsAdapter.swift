//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation

/// Collects HLS playback snapshots and delivers them on an interval.
@MainActor
final class HLSStatsAdapter {
    private let collector: HLSStatsCollector
    private let reporter: HLSStatsReporter
    private let interval: TimeInterval
    private var deliveryCancellable: AnyCancellable?
    private var stopped = false

    init(
        player: AVPlayer,
        callType: String,
        callId: String,
        callSessionId: String,
        unifiedSessionId: String,
        interval: TimeInterval,
        delivery: HLSStatsDelivering,
        now: @escaping () -> Date = { Date() }
    ) {
        self.interval = interval
        collector = HLSStatsCollector(player: player, now: now)
        reporter = HLSStatsReporter(
            callType: callType,
            callId: callId,
            callSessionId: callSessionId,
            unifiedSessionId: unifiedSessionId,
            delivery: delivery,
            now: now
        )
    }

    func start() async {
        guard !stopped else { return }
        collector.start()
        await reporter.sendStarted()
        guard !stopped else { return }
        scheduleDelivery()
    }

    func note(
        status: AVPlayer.TimeControlStatus,
        waitingReason: AVPlayer.WaitingReason?
    ) {
        collector.note(status: status, waitingReason: waitingReason)
    }

    func noteFailure(_ error: Error) {
        collector.noteFailure(error)
    }

    func reportNow() async {
        guard !stopped else { return }
        let sample = collector.snapshot()
        await reporter.sendStats(stats: sample.stats, events: sample.events)
    }

    /// Sends the final snapshot, then `ended`. A second call does nothing.
    @discardableResult
    func stop() -> Task<Void, Never> {
        guard !stopped else { return Task {} }
        stopped = true
        deliveryCancellable?.cancel()
        deliveryCancellable = nil
        let sample = collector.finish()
        return Task {
            if !sample.events.isEmpty {
                await reporter.sendStats(stats: sample.stats, events: sample.events)
            }
            await reporter.sendEnded(errorCode: sample.errorCode)
        }
    }

    private func scheduleDelivery() {
        guard interval > 0 else { return }
        deliveryCancellable = DefaultTimer
            .publish(every: interval)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.reportNow()
                }
            }
    }
}
