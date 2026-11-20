//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation

/// Collects HLS playback snapshots and delivers them on an interval.
///
/// The collector and the interval share one serial queue. A snapshot cannot
/// run between two player observations. The adapter is not isolated to the
/// main actor. The collector hops there only to read the player.
///
/// `didStop` is atomic. The collector's queue orders snapshots, so the
/// adapter can be passed into the timer's sendable closure.
final class HLSStatsAdapter: @unchecked Sendable {
    private let collector: HLSStatsCollector
    private let reporter: HLSStatsReporter
    private let playbackQueue: OperationQueue
    private let interval: TimeInterval
    private let disposableBag = DisposableBag()
    private var deliveryCancellable: AnyCancellable?
    @Atomic private var didStop = false

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
        let playbackQueue = OperationQueue()
        playbackQueue.maxConcurrentOperationCount = 1
        playbackQueue.name = "io.getstream.video.hls-stats"
        self.playbackQueue = playbackQueue
        collector = HLSStatsCollector(
            player: player,
            playbackQueue: playbackQueue,
            now: now
        )
        reporter = HLSStatsReporter(
            callType: callType,
            callId: callId,
            callSessionId: callSessionId,
            unifiedSessionId: unifiedSessionId,
            delivery: delivery,
            now: now
        )
    }

    /// Sends `started`, then publishes a snapshot on each interval.
    ///
    /// A call after ``stopReporting()`` does nothing.
    func startReporting() async {
        guard !didStop else { return }
        await collector.startObservingPlayer()
        guard !didStop else { return }
        await reporter.reportPlaybackStarted()
        guard !didStop else { return }
        scheduleDelivery()
    }

    /// Records a change of `timeControlStatus`. See ``HLSStatsCollector``.
    func recordTimeControlStatus(
        _ status: AVPlayer.TimeControlStatus,
        waitingReason: AVPlayer.WaitingReason?
    ) async {
        await collector.recordTimeControlStatus(status, waitingReason: waitingReason)
    }

    /// Records a player failure. See ``HLSStatsCollector``.
    func recordPlaybackFailure(_ error: Error) async {
        await collector.recordPlaybackFailure(error)
    }

    /// Sends the current snapshot when reporting is still active.
    ///
    /// Player observations already queued are applied first. The player item
    /// is then read on the main actor, and the snapshot is finished on the
    /// serial queue. The queue is not held across that main-actor read.
    func publishCurrentSnapshot() async {
        guard !didStop else { return }
        guard await collector.waitUntilIdle() else { return }
        let measurement = await collector.readPlayerMeasurement()
        guard !didStop else { return }
        guard let sample = await collector.completeSnapshot(measurement) else { return }
        await reporter.reportPlaybackStats(stats: sample.stats, events: sample.events)
    }

    /// Sends the final snapshot, then `ended`.
    ///
    /// A second call does nothing. The returned task finishes after `ended`
    /// has been handed to delivery.
    @discardableResult
    func stopReporting() -> Task<Void, Never> {
        guard !didStop else { return Task {} }
        didStop = true
        deliveryCancellable?.cancel()
        deliveryCancellable = nil
        return Task { [collector, reporter] in
            guard await collector.beginStop() else { return }
            let measurement = await collector.readPlayerMeasurement()
            guard let sample = await collector.finishStop(measurement) else { return }
            if !sample.events.isEmpty {
                await reporter.reportPlaybackStats(
                    stats: sample.stats,
                    events: sample.events
                )
            }
            await reporter.reportPlaybackEnded(errorCode: sample.errorCode)
        }
    }

    private func scheduleDelivery() {
        guard interval > 0 else { return }
        deliveryCancellable = DefaultTimer
            .publish(every: interval)
            .sinkTask(storeIn: disposableBag) { [weak self] _ in
                await self?.publishCurrentSnapshot()
            }
    }
}
