//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation

/// Reports HLS playback to the coordinator: `started` on the first play,
/// `stats` on an interval, and `ended` on stop. A viewer that never plays
/// sends nothing.
///
/// A snapshot hands its events to the reporter on the collector's serial
/// queue, so a later stop cannot send `ended` ahead of them. `queue` guards
/// the start and stop flags and the timer, which different threads reach.
final class HLSStatsAdapter: @unchecked Sendable {
    private let collector: HLSStatsCollector
    private let reporter: HLSStatsReporter
    private let interval: TimeInterval
    private let disposableBag = DisposableBag()
    private let queue = UnfairQueue()
    private var didStart = false
    private var didStop = false
    private var deliveryCancellable: AnyCancellable?

    init(
        player: AVPlayer,
        api: DefaultAPIEndpoints,
        callType: String,
        callId: String,
        callSessionId: String,
        unifiedSessionId: String,
        statsToken: String,
        interval: TimeInterval,
        retryPolicy: RetryPolicy = .hlsStatsReporting,
        currentDate: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.interval = interval
        collector = HLSStatsCollector(
            player: player,
            currentDate: currentDate
        )
        reporter = HLSStatsReporter(
            api: api,
            callType: callType,
            callId: callId,
            callSessionId: callSessionId,
            unifiedSessionId: unifiedSessionId,
            statsToken: statsToken,
            retryPolicy: retryPolicy,
            currentDate: currentDate
        )
        collector.onFirstPlay = { [weak self] in self?.reportPlaybackStarted() }
    }

    // MARK: - Reporting

    /// Starts watching the player. The call waits for the observers only. No
    /// report goes out before the player plays.
    ///
    /// A call after ``stopReporting()`` does nothing.
    func startReporting() async {
        await collector.startObservingPlayer()
    }

    /// Sends the current snapshot when reporting is still active.
    ///
    /// The collector applies the player observations already queued and
    /// reads the player on the main actor.
    ///
    /// A snapshot is skipped while an earlier report is still on its way.
    /// A refused stats token ends the interval.
    func publishCurrentSnapshot() async {
        guard !isStopped else { return }
        guard !reporter.isRejected else {
            cancelDelivery()
            return
        }
        guard !reporter.isBusy else { return }
        await collector.snapshot { [reporter] stats, events in
            reporter.reportPlaybackStats(stats: stats, events: events)
        }
    }

    /// Stops the interval, then sends `ended` with the final snapshot and the
    /// pending events when `started` was sent.
    ///
    /// A second call does nothing. The call waits for the final read of the
    /// player, so the caller can clear the player after it. It does not wait
    /// for the network.
    func stopReporting() async {
        guard let sendEnded = markStopped() else { return }

        let sample = await collector.stop()
        guard sendEnded, let sample else { return }
        reporter.reportPlaybackEnded(
            stats: sample.stats,
            events: sample.events,
            errorCode: sample.errorCode
        )
    }

    // MARK: - Private Helpers

    /// Marks the adapter stopped and ends the interval. Returns whether
    /// `started` was sent, or nil when the adapter was already stopped.
    private func markStopped() -> Bool? {
        queue.sync {
            guard !didStop else { return nil }
            didStop = true
            deliveryCancellable?.cancel()
            deliveryCancellable = nil
            return didStart
        }
    }

    private var isStopped: Bool {
        queue.sync { didStop }
    }

    /// Runs on the collector's queue when the player first plays. The report
    /// is queued before `queue` is released, so a stop cannot queue `ended`
    /// ahead of `started`.
    private func reportPlaybackStarted() {
        queue.sync {
            guard !didStop, !didStart else { return }
            didStart = true
            reporter.reportPlaybackStarted()
            guard interval > 0 else { return }
            deliveryCancellable = DefaultTimer
                .publish(every: interval)
                .sinkTask(storeIn: disposableBag) { [weak self] _ in
                    await self?.publishCurrentSnapshot()
                }
        }
    }

    private func cancelDelivery() {
        queue.sync {
            deliveryCancellable?.cancel()
            deliveryCancellable = nil
        }
    }
}
