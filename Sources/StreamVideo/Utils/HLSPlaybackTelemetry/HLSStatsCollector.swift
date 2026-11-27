//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation

/// Watches one `AVPlayer` and keeps the latest playback snapshot.
///
/// Player observers add their change to a serial queue. The queue applies the
/// changes one at a time, so a stall and the following play cannot be
/// recorded out of order. The collector is not isolated to the main actor.
/// ``snapshot(deliver:)`` and ``stop()`` hop to the main actor to read the
/// player, because that is where `AVPlayer` exposes the item, the access log,
/// and the presentation size. They hold the queue while they read, so the
/// stall counters cannot change in between.
///
/// A stall opens when playback that was running waits to play again, for
/// any reason except that there is no item to play. The initial load and a
/// pause are not stalls.
///
/// Mutable playback state is only touched on `playbackQueue`. That queue is
/// what makes the collector safe to pass into a sendable closure.
final class HLSStatsCollector: @unchecked Sendable {
    /// Tests suspend and drain it to control when changes apply.
    let playbackQueue = OperationQueue(maxConcurrentOperationCount: 1)

    private let player: AVPlayer
    private let currentDate: @Sendable () -> Date
    private var observations: [NSKeyValueObservation] = []
    private var failureCancellable: AnyCancellable?
    private var didStop = false
    private var sawFirstPlay = false
    private var lastStatus: AVPlayer.TimeControlStatus?
    private var stallBegan: Date?
    private var stallCount = 0
    private var stallDurationMs: Int = 0
    private var maxStallMs: Int = 0
    private var events: [HLSPlayerEvent] = []
    private var lastErrorCode: String?
    private var reportedQuality = false
    private var lastBitrate = 0
    private var lastWidth = 0
    private var lastHeight = 0

    /// Called on the serial queue the first time the player plays. Set it
    /// before ``startObservingPlayer()``.
    var onFirstPlay: (@Sendable () -> Void)?

    init(
        player: AVPlayer,
        currentDate: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.player = player
        self.currentDate = currentDate
    }

    // MARK: - Lifecycle

    /// Starts watching `timeControlStatus`, and the status and error of the
    /// current item.
    ///
    /// A second call after ``stop()`` does nothing. The call returns once
    /// the observers are installed.
    func startObservingPlayer() async {
        try? await playbackQueue.addSynchronousTaskOperation { [weak self] in
            self?.installObservations()
        }
    }

    /// Reads the player and passes the snapshot with the pending events to
    /// `deliver`. Does nothing after ``stop()``.
    ///
    /// `deliver` runs on the serial queue, before ``stop()`` can start. A
    /// caller that handed the drained events over later could lose them
    /// when a stop ends the session in between.
    func snapshot(
        deliver: @escaping @Sendable (HLSPlaybackStats, [HLSPlayerEvent]) -> Void
    ) async {
        try? await playbackQueue.addSynchronousTaskOperation { [weak self] in
            guard let self, !didStop else { return }
            let stats = await readPlaybackStats(
                stallCount: stallCount,
                stallDurationMs: stallDurationMs,
                maxStallMs: maxStallMs
            )
            recordQualityChangeIfNeeded(stats)
            lastBitrate = stats.bitrateKbps
            lastWidth = stats.width
            lastHeight = stats.height
            reportedQuality = true
            deliver(stats, drainEvents())
        }
    }

    /// Stops observation, closes an open stall, and returns the final
    /// snapshot with the pending events and the last playback error code.
    ///
    /// The final read of the player is done when this returns, so the caller
    /// can clear the player after it. A second call returns nil.
    func stop() async -> (
        stats: HLSPlaybackStats,
        events: [HLSPlayerEvent],
        errorCode: String?
    )? {
        try? await playbackQueue.addSynchronousTaskOperation { [weak self] in
            guard let self, !didStop else { return nil }
            didStop = true
            failureCancellable = nil
            observations.removeAll()
            endStallIfOneIsOpen(at: currentDate())
            let stats = await readPlaybackStats(
                stallCount: stallCount,
                stallDurationMs: stallDurationMs,
                maxStallMs: maxStallMs
            )
            return (stats, drainEvents(), lastErrorCode)
        }
    }

    // MARK: - Observation

    private func installObservations() {
        guard observations.isEmpty, !didStop else { return }
        // The current value counts too. The player can already play before
        // the observer exists.
        observations.append(
            player.observe(\.timeControlStatus, options: [.initial, .new]) { [weak self] player, _ in
                let status = player.timeControlStatus
                let reason = player.reasonForWaitingToPlay
                self?.enqueue { $0.applyTimeControl(status: status, waitingReason: reason, at: $1) }
            }
        )
        // A stream that cannot load or play fails on the item, not on the
        // player.
        observations.append(
            player.observe(\.currentItem?.status, options: [.initial, .new]) { [weak self] player, _ in
                self?.enqueueFailure(player.currentItem?.error)
            }
        )
        observations.append(
            player.observe(\.currentItem?.error, options: [.new]) { [weak self] player, _ in
                self?.enqueueFailure(player.currentItem?.error)
            }
        )
        // Playback can also fail after it started, for example when the
        // stream is cut.
        failureCancellable = NotificationCenter.default
            .publisher(for: .AVPlayerItemFailedToPlayToEndTime)
            .sink { [weak self] notification in
                guard
                    let self,
                    (notification.object as? AVPlayerItem) === player.currentItem
                else { return }
                enqueueFailure(
                    notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
                )
            }
    }

    /// Adds a change to the serial queue. A change that arrives after
    /// ``stop()`` is dropped. The change gets the time it was observed,
    /// because the queue can run it later.
    private func enqueue(
        _ change: @escaping @Sendable (HLSStatsCollector, Date) -> Void
    ) {
        let observedAt = currentDate()
        playbackQueue.addOperation { [weak self] in
            guard let self, !didStop else { return }
            change(self, observedAt)
        }
    }

    private func enqueueFailure(_ error: Error?) {
        guard let error else { return }
        let code = playbackErrorCode(error)
        enqueue { $0.applyFailure(code: code, at: $1) }
    }

    // MARK: - Private Helpers

    private func applyTimeControl(
        status: AVPlayer.TimeControlStatus,
        waitingReason: AVPlayer.WaitingReason?,
        at date: Date
    ) {
        defer { lastStatus = status }
        switch status {
        case .playing:
            endStallIfOneIsOpen(at: date)
            guard !sawFirstPlay else { return }
            sawFirstPlay = true
            appendEvent(type: "first_frame", at: date)
            onFirstPlay?()
        case .waitingToPlayAtSpecifiedRate:
            // Only playback that was running can stall, as on Android. The
            // initial load waits to play too, and it is not a stall. No item
            // to play is not a stall either, whatever the player was doing.
            guard
                waitingReason != .noItemToPlay,
                lastStatus == .playing,
                stallBegan == nil
            else { return }
            stallBegan = date
            stallCount += 1
            appendEvent(type: "stall_start", at: date)
        case .paused:
            endStallIfOneIsOpen(at: date)
        @unknown default:
            break
        }
    }

    private func applyFailure(code: String, at date: Date) {
        guard lastErrorCode != code else { return }
        lastErrorCode = code
        appendEvent(type: "error", data: ["code": .string(code)], at: date)
    }

    private func endStallIfOneIsOpen(at date: Date) {
        guard let stallBegan else { return }
        let duration = max(0, date.timeIntervalSince(stallBegan))
        let durationMs = milliseconds(duration)
        stallDurationMs += durationMs
        maxStallMs = max(maxStallMs, durationMs)
        self.stallBegan = nil
        appendEvent(
            type: "stall_end",
            data: ["duration_ms": .number(Double(durationMs))],
            at: date
        )
    }

    /// Records `quality_change` when a later snapshot differs in bitrate or
    /// size.
    ///
    /// The first snapshot only stores the baseline. It does not emit an event.
    private func recordQualityChangeIfNeeded(_ sample: HLSPlaybackStats) {
        guard reportedQuality else { return }
        let changed = sample.bitrateKbps != lastBitrate
            || sample.width != lastWidth
            || sample.height != lastHeight
        guard changed else { return }
        appendEvent(
            type: "quality_change",
            data: [
                "bitrate_kbps": .number(Double(sample.bitrateKbps)),
                "width": .number(Double(sample.width)),
                "height": .number(Double(sample.height))
            ],
            at: currentDate()
        )
    }

    private func appendEvent(
        type: String,
        data: [String: RawJSON]? = nil,
        at date: Date
    ) {
        events.append(
            HLSPlayerEvent(
                data: data,
                timestamp: Int(date.timeIntervalSince1970 * 1000),
                type: type
            )
        )
    }

    private func drainEvents() -> [HLSPlayerEvent] {
        defer { events.removeAll() }
        return events
    }

    /// Reads the player item on the main actor.
    ///
    /// The stall counters are passed in. They belong to the serial queue, and
    /// this hop must not read them again from the main actor.
    @MainActor
    private func readPlaybackStats(
        stallCount: Int,
        stallDurationMs: Int,
        maxStallMs: Int
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
            bitrateKbps: max(bitrate, 0),
            bufferLengthMs: milliseconds((loadedEnd ?? safeCurrent) - safeCurrent),
            droppedFrames: dropped,
            height: Int(size.height.rounded()),
            liveLatencyMs: milliseconds((liveEnd ?? safeCurrent) - safeCurrent),
            maxStallDurationMs: maxStallMs,
            stallCount: stallCount,
            stallDurationMs: stallDurationMs,
            watchDurationMs: milliseconds(watched),
            width: Int(size.width.rounded())
        )
    }

    private func milliseconds(_ seconds: TimeInterval) -> Int {
        guard seconds.isFinite, seconds > 0 else { return 0 }
        return Int((seconds * 1000).rounded())
    }

    private func playbackErrorCode(_ error: Error) -> String {
        let nsError = error as NSError
        return String("\(nsError.domain) \(nsError.code)".prefix(128))
    }
}
