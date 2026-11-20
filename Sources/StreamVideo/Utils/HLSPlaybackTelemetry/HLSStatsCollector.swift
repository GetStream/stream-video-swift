//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

/// Watches one `AVPlayer` and keeps the latest playback snapshot.
@MainActor
final class HLSStatsCollector {
    private let player: AVPlayer
    private let now: () -> Date
    private var observations: [NSKeyValueObservation] = []
    private var stopped = false
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

    init(player: AVPlayer, now: @escaping () -> Date = { Date() }) {
        self.player = player
        self.now = now
    }

    func start() {
        guard !stopped else { return }
        observations.append(
            player.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
                let status = player.timeControlStatus
                let reason = player.reasonForWaitingToPlay
                Task { @MainActor in
                    self?.note(status: status, waitingReason: reason)
                }
            }
        )
        observations.append(
            player.observe(\.status, options: [.new]) { [weak self] player, _ in
                guard let error = player.error else { return }
                Task { @MainActor in
                    self?.noteFailure(error)
                }
            }
        )
    }

    func note(
        status: AVPlayer.TimeControlStatus,
        waitingReason: AVPlayer.WaitingReason?
    ) {
        guard !stopped else { return }
        switch status {
        case .playing:
            endStallIfNeeded()
            guard !sawFirstFrame else { return }
            sawFirstFrame = true
            events.append(
                HLSStatsEvent(type: "first_frame", timestamp: timestamp(), data: [:])
            )
        case .waitingToPlayAtSpecifiedRate:
            guard waitingReason == .toMinimizeStalls, stallBegan == nil else { return }
            stallBegan = now()
            stallCount += 1
            events.append(
                HLSStatsEvent(type: "stall_start", timestamp: timestamp(), data: [:])
            )
        case .paused:
            endStallIfNeeded()
        @unknown default:
            break
        }
    }

    func noteFailure(_ error: Error) {
        guard !stopped else { return }
        let code = errorCode(error)
        guard lastErrorCode != code else { return }
        lastErrorCode = code
        events.append(
            HLSStatsEvent(
                type: "error",
                timestamp: timestamp(),
                data: ["code": code]
            )
        )
    }

    /// The current snapshot. Pending events are drained.
    func snapshot() -> (stats: HLSPlaybackStats, events: [HLSStatsEvent]) {
        let stats = measurement()
        noteQualityChange(stats)
        let pending = events
        events.removeAll()
        lastBitrate = stats.bitrateKbps
        lastWidth = stats.width
        lastHeight = stats.height
        reportedQuality = true
        return (stats, pending)
    }

    /// Stops observation and returns the final snapshot, including an open stall.
    func finish() -> (stats: HLSPlaybackStats, events: [HLSStatsEvent], errorCode: String?) {
        stopped = true
        observations.removeAll()
        endStallIfNeeded()
        let stats = measurement()
        let pending = events
        events.removeAll()
        return (stats, pending, lastErrorCode)
    }

    private func endStallIfNeeded() {
        guard let stallBegan else { return }
        let duration = max(0, now().timeIntervalSince(stallBegan))
        let durationMs = milliseconds(duration)
        stallDurationMs += durationMs
        maxStallMs = max(maxStallMs, durationMs)
        self.stallBegan = nil
        events.append(
            HLSStatsEvent(
                type: "stall_end",
                timestamp: timestamp(),
                data: ["duration_ms": String(durationMs)]
            )
        )
    }

    private func noteQualityChange(_ sample: HLSPlaybackStats) {
        guard reportedQuality else { return }
        let changed = sample.bitrateKbps != lastBitrate
            || sample.width != lastWidth
            || sample.height != lastHeight
        guard changed else { return }
        events.append(
            HLSStatsEvent(
                type: "quality_change",
                timestamp: timestamp(),
                data: [
                    "bitrate_kbps": String(sample.bitrateKbps),
                    "width": String(sample.width),
                    "height": String(sample.height)
                ]
            )
        )
    }

    private func measurement() -> HLSPlaybackStats {
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

    private func timestamp() -> Int64 {
        Int64(now().timeIntervalSince1970 * 1000)
    }

    private func milliseconds(_ seconds: TimeInterval) -> Int64 {
        guard seconds.isFinite, seconds > 0 else { return 0 }
        return Int64((seconds * 1000).rounded())
    }

    private func errorCode(_ error: Error) -> String {
        let nsError = error as NSError
        return String("\(nsError.domain) \(nsError.code)".prefix(128))
    }
}
