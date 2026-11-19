//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

/// Watches one `AVPlayer` and reports playback to ``HLSPlaybackReporter``.
@MainActor
@_spi(StreamVideo) public final class HLSPlaybackTracker: HLSPlaybackTracking {

    private let player: AVPlayer
    private let reporter: HLSPlaybackReporter
    private let interval: TimeInterval
    private let now: () -> Date
    private var observations: [NSKeyValueObservation] = []
    private var reportTask: Task<Void, Never>?
    private var stopped = false
    private var sawFirstFrame = false
    private var stallBegan: Date?
    private var stallCount = 0
    private var stallDurationMs: Int64 = 0
    private var maxStallMs: Int64 = 0
    private var events: [HLSPlaybackEvent] = []
    private var lastErrorCode: String?
    private var reportedQuality = false
    private var lastBitrate = 0
    private var lastWidth = 0
    private var lastHeight = 0

    init(
        player: AVPlayer,
        reporter: HLSPlaybackReporter,
        interval: TimeInterval,
        now: @escaping () -> Date = { Date() }
    ) {
        self.player = player
        self.reporter = reporter
        self.interval = interval
        self.now = now
    }

    public func start() async {
        guard !stopped else { return }
        observe()
        await reporter.start()
        guard !stopped else { return }
        let interval = interval
        reportTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                guard !Task.isCancelled else { return }
                await self?.reportNow()
            }
        }
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
                HLSPlaybackEvent(
                    type: "first_frame",
                    timestamp: timestamp(),
                    data: [:]
                )
            )
        case .waitingToPlayAtSpecifiedRate:
            guard waitingReason == .toMinimizeStalls, stallBegan == nil else { return }
            stallBegan = now()
            stallCount += 1
            events.append(
                HLSPlaybackEvent(
                    type: "stall_start",
                    timestamp: timestamp(),
                    data: [:]
                )
            )
        case .paused:
            endStallIfNeeded()
        @unknown default:
            break
        }
    }

    func noteFailure(_ error: Error) {
        guard !stopped else { return }
        let code = Self.errorCode(error)
        guard lastErrorCode != code else { return }
        lastErrorCode = code
        events.append(
            HLSPlaybackEvent(
                type: "error",
                timestamp: timestamp(),
                data: ["code": code]
            )
        )
    }

    func reportNow() async {
        guard !stopped else { return }
        let sample = measurement()
        noteQualityChange(sample)
        let pending = events
        events.removeAll()
        await reporter.report(measurement: sample, events: pending)
        lastBitrate = sample.bitrateKbps
        lastWidth = sample.width
        lastHeight = sample.height
        reportedQuality = true
    }

    @discardableResult
    public func stop() -> Task<Void, Never> {
        guard !stopped else { return Task {} }
        stopped = true
        reportTask?.cancel()
        reportTask = nil
        observations.removeAll()
        endStallIfNeeded()
        let code = lastErrorCode
        let pending = events
        events.removeAll()
        let sample = measurement()
        return Task {
            if !pending.isEmpty {
                await reporter.report(measurement: sample, events: pending)
            }
            await reporter.stop(errorCode: code)
        }
    }

    private func observe() {
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

    private func endStallIfNeeded() {
        guard let stallBegan else { return }
        let duration = max(0, now().timeIntervalSince(stallBegan))
        let durationMs = Self.milliseconds(duration)
        stallDurationMs += durationMs
        maxStallMs = max(maxStallMs, durationMs)
        self.stallBegan = nil
        events.append(
            HLSPlaybackEvent(
                type: "stall_end",
                timestamp: timestamp(),
                data: ["duration_ms": String(durationMs)]
            )
        )
    }

    private func noteQualityChange(_ sample: HLSPlaybackMeasurement) {
        guard reportedQuality else { return }
        let changed = sample.bitrateKbps != lastBitrate
            || sample.width != lastWidth
            || sample.height != lastHeight
        guard changed else { return }
        events.append(
            HLSPlaybackEvent(
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

    private func measurement() -> HLSPlaybackMeasurement {
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
        return HLSPlaybackMeasurement(
            watchDurationMs: Self.milliseconds(watched),
            stallCount: stallCount,
            stallDurationMs: stallDurationMs,
            maxStallDurationMs: maxStallMs,
            droppedFrames: dropped,
            bitrateKbps: max(bitrate, 0),
            bufferLengthMs: Int(Self.milliseconds((loadedEnd ?? safeCurrent) - safeCurrent)),
            liveLatencyMs: Int(Self.milliseconds((liveEnd ?? safeCurrent) - safeCurrent)),
            width: Int(size.width.rounded()),
            height: Int(size.height.rounded())
        )
    }

    private func timestamp() -> Int64 {
        Int64(now().timeIntervalSince1970 * 1000)
    }

    private static func milliseconds(_ seconds: TimeInterval) -> Int64 {
        guard seconds.isFinite, seconds > 0 else { return 0 }
        return Int64((seconds * 1000).rounded())
    }

    static func errorCode(_ error: Error) -> String {
        let nsError = error as NSError
        return String("\(nsError.domain) \(nsError.code)".prefix(128))
    }
}

/// The player store keeps this for one HLS player and stops it on release.
@MainActor
@_spi(StreamVideo) public protocol HLSPlaybackTracking: AnyObject {
    func start() async
    @discardableResult
    func stop() -> Task<Void, Never>
}

/// Builds playback reporting for the player store.
///
/// Returns nil when the call has no session id or no unified session id,
/// or when no sender is available.
@MainActor
@_spi(StreamVideo) public func makeHLSPlaybackTracking(
    player: AVPlayer,
    call: Call,
    sender: (any HLSStatsSending)?
) -> (any HLSPlaybackTracking)? {
    let callSessionId = call.state.session?.id ?? ""
    guard !callSessionId.isEmpty, !call.state.unifiedSessionId.isEmpty else {
        return nil
    }
    let api = sender ?? (call.coordinatorClient as? any HLSStatsSending)
    guard let api else { return nil }
    let seconds = call.state.statsCollectionInterval > 0
        ? TimeInterval(call.state.statsCollectionInterval)
        : 5
    let reporter = HLSPlaybackReporter(
        callType: call.callType,
        callId: call.callId,
        callSessionId: callSessionId,
        unifiedSessionId: call.state.unifiedSessionId,
        sender: api
    )
    return HLSPlaybackTracker(
        player: player,
        reporter: reporter,
        interval: seconds
    )
}
