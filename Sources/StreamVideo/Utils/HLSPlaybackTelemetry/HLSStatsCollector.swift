//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation

/// Watches one `AVPlayer` and keeps the latest playback snapshot.
///
/// Player observers only publish a ``HLSPlayerObservation``. A serial queue
/// applies those observations one at a time, so a stall and the following
/// play cannot be recorded out of order. The collector is not isolated to
/// the main actor. ``readPlayerMeasurement()`` is the read that hops to the
/// main actor, because that is where `AVPlayer` exposes the item, the access
/// log, and the presentation size.
///
/// Mutable playback state is only touched on `playbackQueue`. That queue is
/// what makes the collector safe to pass into a sendable closure.
final class HLSStatsCollector: @unchecked Sendable {
    private let playbackQueue: OperationQueue

    private let player: AVPlayer
    private let now: () -> Date
    private let playerObservations = PassthroughSubject<HLSPlayerObservation, Never>()
    private var observations: [NSKeyValueObservation] = []
    private var observationCancellable: AnyCancellable?
    private var didStop = false
    private var sawFirstFrame = false
    private var stallBegan: Date?
    private var stallCount = 0
    private var stallDurationMs: Int64 = 0
    private var maxStallMs: Int64 = 0
    private var events: [HLSStatsEvent] = []
    private var lastErrorCode: String?
    private var reportedQuality = false
    private var lastBitrate = 0
    private var lastWidth = 0
    private var lastHeight = 0

    init(
        player: AVPlayer,
        playbackQueue: OperationQueue,
        now: @escaping () -> Date = { Date() }
    ) {
        self.player = player
        self.playbackQueue = playbackQueue
        self.now = now
    }

    /// Starts watching `timeControlStatus` and `status`.
    ///
    /// A second call after ``stopObservingPlayer()`` does nothing. The
    /// returned task finishes once the observers are installed.
    func startObservingPlayer() async {
        try? await playbackQueue.addSynchronousTaskOperation { [weak self] in
            self?.installObservations()
        }
    }

    /// Records a change of `timeControlStatus`.
    ///
    /// `.waitingToPlayAtSpecifiedRate` with `.toMinimizeStalls` opens a stall.
    /// `.playing` closes an open stall and records `first_frame` once.
    /// `.paused` closes an open stall. The call finishes after the serial
    /// queue has applied the change.
    func recordTimeControlStatus(
        _ status: AVPlayer.TimeControlStatus,
        waitingReason: AVPlayer.WaitingReason?
    ) async {
        try? await playbackQueue.addSynchronousTaskOperation { [weak self] in
            self?.apply(
                .timeControl(status: status, waitingReason: waitingReason)
            )
        }
    }

    /// Records a player failure.
    ///
    /// The same error code is recorded once. The code is the error domain
    /// and the error code, cut to 128 characters. The call finishes after
    /// the serial queue has applied the failure.
    func recordPlaybackFailure(_ error: Error) async {
        let code = Self.playbackErrorCode(error)
        try? await playbackQueue.addSynchronousTaskOperation { [weak self] in
            self?.apply(.failure(code: code))
        }
    }

    /// Waits until observations already queued have been applied.
    ///
    /// Returns false after ``beginStop()``. The queue is free when this
    /// returns, so the caller can read the player on the main actor without
    /// the queue waiting on that read.
    func waitUntilIdle() async -> Bool {
        (try? await playbackQueue.addSynchronousTaskOperation { [weak self] in
            self?.didStop == false
        }) ?? false
    }

    /// Reads the player item on the main actor.
    ///
    /// Stall counters in the result are placeholders. ``completeSnapshot(_:)``
    /// and ``finishStop(_:)`` replace them with the counters on the serial
    /// queue. This method does not take the queue.
    @MainActor
    func readPlayerMeasurement() -> HLSPlaybackStats {
        readPlaybackStats(stallCount: 0, stallDurationMs: 0, maxStallMs: 0)
    }

    /// Finishes a periodic snapshot on the serial queue.
    ///
    /// Stall counters come from the queue, not from `measurement`. Pending
    /// events are drained. Returns nil after ``beginStop()``.
    func completeSnapshot(
        _ measurement: HLSPlaybackStats
    ) async -> (stats: HLSPlaybackStats, events: [HLSStatsEvent])? {
        try? await playbackQueue.addSynchronousTaskOperation { [weak self] in
            guard let self, !self.didStop else { return nil }
            return self.snapshot(from: measurement, recordQuality: true)
        }
    }

    /// Stops observation and closes an open stall.
    ///
    /// A second call returns false. The caller then reads the player and
    /// calls ``finishStop(_:)``.
    func beginStop() async -> Bool {
        (try? await playbackQueue.addSynchronousTaskOperation { [weak self] in
            guard let self, !self.didStop else { return false }
            self.didStop = true
            self.observationCancellable?.cancel()
            self.observationCancellable = nil
            self.observations.removeAll()
            self.endStallIfOneIsOpen()
            return true
        }) ?? false
    }

    /// Builds the final snapshot after ``beginStop()``.
    ///
    /// Returns nil when stop did not begin. Pending events, including a
    /// stall that ``beginStop()`` closed, are drained.
    func finishStop(
        _ measurement: HLSPlaybackStats
    ) async -> (stats: HLSPlaybackStats, events: [HLSStatsEvent], errorCode: String?)? {
        try? await playbackQueue.addSynchronousTaskOperation { [weak self] in
            guard let self, self.didStop else { return nil }
            let sample = self.snapshot(from: measurement, recordQuality: false)
            return (sample.stats, sample.events, self.lastErrorCode)
        }
    }

    private func installObservations() {
        guard observationCancellable == nil, !didStop else { return }
        let playerObservations = playerObservations
        observationCancellable = playerObservations
            .sinkTask(queue: playbackQueue) { [weak self] observation in
                self?.apply(observation)
            }
        observations.append(
            player.observe(\.timeControlStatus, options: [.new]) { [weak playerObservations] player, _ in
                let status = player.timeControlStatus
                let reason = player.reasonForWaitingToPlay
                playerObservations?.send(
                    .timeControl(status: status, waitingReason: reason)
                )
            }
        )
        observations.append(
            player.observe(\.status, options: [.new]) { [weak playerObservations] player, _ in
                guard let error = player.error else { return }
                let code = Self.playbackErrorCode(error)
                playerObservations?.send(.failure(code: code))
            }
        )
    }

    private func apply(_ observation: HLSPlayerObservation) {
        guard !didStop else { return }
        switch observation {
        case let .timeControl(status, waitingReason):
            applyTimeControl(status: status, waitingReason: waitingReason)
        case let .failure(code):
            applyFailure(code: code)
        }
    }

    private func applyTimeControl(
        status: AVPlayer.TimeControlStatus,
        waitingReason: AVPlayer.WaitingReason?
    ) {
        switch status {
        case .playing:
            endStallIfOneIsOpen()
            guard !sawFirstFrame else { return }
            sawFirstFrame = true
            events.append(
                HLSStatsEvent(type: "first_frame", timestamp: unixTimestampMilliseconds(), data: [:])
            )
        case .waitingToPlayAtSpecifiedRate:
            guard waitingReason == .toMinimizeStalls, stallBegan == nil else { return }
            stallBegan = now()
            stallCount += 1
            events.append(
                HLSStatsEvent(type: "stall_start", timestamp: unixTimestampMilliseconds(), data: [:])
            )
        case .paused:
            endStallIfOneIsOpen()
        @unknown default:
            break
        }
    }

    private func applyFailure(code: String) {
        guard lastErrorCode != code else { return }
        lastErrorCode = code
        events.append(
            HLSStatsEvent(
                type: "error",
                timestamp: unixTimestampMilliseconds(),
                data: ["code": code]
            )
        )
    }

    private func snapshot(
        from measurement: HLSPlaybackStats,
        recordQuality: Bool
    ) -> (stats: HLSPlaybackStats, events: [HLSStatsEvent]) {
        let stats = HLSPlaybackStats(
            watchDurationMs: measurement.watchDurationMs,
            stallCount: stallCount,
            stallDurationMs: stallDurationMs,
            maxStallDurationMs: maxStallMs,
            droppedFrames: measurement.droppedFrames,
            bitrateKbps: measurement.bitrateKbps,
            bufferLengthMs: measurement.bufferLengthMs,
            liveLatencyMs: measurement.liveLatencyMs,
            width: measurement.width,
            height: measurement.height
        )
        if recordQuality {
            recordQualityChangeIfNeeded(stats)
            lastBitrate = stats.bitrateKbps
            lastWidth = stats.width
            lastHeight = stats.height
            reportedQuality = true
        }
        let pending = events
        events.removeAll()
        return (stats, pending)
    }

    private func endStallIfOneIsOpen() {
        guard let stallBegan else { return }
        let duration = max(0, now().timeIntervalSince(stallBegan))
        let durationMs = milliseconds(duration)
        stallDurationMs += durationMs
        maxStallMs = max(maxStallMs, durationMs)
        self.stallBegan = nil
        events.append(
            HLSStatsEvent(
                type: "stall_end",
                timestamp: unixTimestampMilliseconds(),
                data: ["duration_ms": String(durationMs)]
            )
        )
    }

    /// Records `quality_change` when a later snapshot differs in bitrate or size.
    ///
    /// The first snapshot only stores the baseline. It does not emit an event.
    private func recordQualityChangeIfNeeded(_ sample: HLSPlaybackStats) {
        guard reportedQuality else { return }
        let changed = sample.bitrateKbps != lastBitrate
            || sample.width != lastWidth
            || sample.height != lastHeight
        guard changed else { return }
        events.append(
            HLSStatsEvent(
                type: "quality_change",
                timestamp: unixTimestampMilliseconds(),
                data: [
                    "bitrate_kbps": String(sample.bitrateKbps),
                    "width": String(sample.width),
                    "height": String(sample.height)
                ]
            )
        )
    }

    /// Reads the player item on the main actor.
    ///
    /// Stall counters are passed in. They belong to the serial queue, and
    /// this hop must not read them again from the main actor.
    @MainActor
    private func readPlaybackStats(
        stallCount: Int,
        stallDurationMs: Int64,
        maxStallMs: Int64
    ) -> HLSPlaybackStats {
        let item = player.currentItem
        let logEvents = item?.accessLog()?.events ?? []
        let watched = logEvents.reduce(0.0) { $0 + $1.durationWatched }
        let dropped = logEvents.reduce(0) { $0 + $1.numberOfDroppedVideoFrames }
        let bitrate = Int((logEvents.last?.indicatedBitrate ?? 0) / 1000)
        let current = item?.currentTime().seconds ?? 0
        let loadedEnd = item?.loadedTimeRanges
            .map { $0.timeRangeValue.end.seconds }
            .filter(\.isFinite)
            .max()
        let liveEnd = item?.seekableTimeRanges
            .map { $0.timeRangeValue.end.seconds }
            .filter(\.isFinite)
            .max()
        let size = item?.presentationSize ?? .zero
        let safeCurrent = current.isFinite ? current : 0
        return HLSPlaybackStats(
            watchDurationMs: milliseconds(watched),
            stallCount: stallCount,
            stallDurationMs: stallDurationMs,
            maxStallDurationMs: maxStallMs,
            droppedFrames: dropped,
            bitrateKbps: max(bitrate, 0),
            bufferLengthMs: Int(milliseconds((loadedEnd ?? safeCurrent) - safeCurrent)),
            liveLatencyMs: Int(milliseconds((liveEnd ?? safeCurrent) - safeCurrent)),
            width: Int(size.width.rounded()),
            height: Int(size.height.rounded())
        )
    }

    private func unixTimestampMilliseconds() -> Int64 {
        Int64(now().timeIntervalSince1970 * 1000)
    }

    private func milliseconds(_ seconds: TimeInterval) -> Int64 {
        guard seconds.isFinite, seconds > 0 else { return 0 }
        return Int64((seconds * 1000).rounded())
    }

    private static func playbackErrorCode(_ error: Error) -> String {
        let nsError = error as NSError
        return String("\(nsError.domain) \(nsError.code)".prefix(128))
    }
}
