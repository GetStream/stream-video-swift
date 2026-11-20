//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A full playback snapshot. The latest report replaces earlier ones.
final class HLSPlaybackStats: Encodable, Sendable {
    let watchDurationMs: Int64
    let stallCount: Int
    let stallDurationMs: Int64
    let maxStallDurationMs: Int64
    let droppedFrames: Int
    let bitrateKbps: Int
    let bufferLengthMs: Int
    let liveLatencyMs: Int
    let width: Int
    let height: Int

    init(
        watchDurationMs: Int64 = 0,
        stallCount: Int = 0,
        stallDurationMs: Int64 = 0,
        maxStallDurationMs: Int64 = 0,
        droppedFrames: Int = 0,
        bitrateKbps: Int = 0,
        bufferLengthMs: Int = 0,
        liveLatencyMs: Int = 0,
        width: Int = 0,
        height: Int = 0
    ) {
        self.watchDurationMs = watchDurationMs
        self.stallCount = stallCount
        self.stallDurationMs = stallDurationMs
        self.maxStallDurationMs = maxStallDurationMs
        self.droppedFrames = droppedFrames
        self.bitrateKbps = bitrateKbps
        self.bufferLengthMs = bufferLengthMs
        self.liveLatencyMs = liveLatencyMs
        self.width = width
        self.height = height
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(watchDurationMs, forKey: .watchDurationMs)
        try container.encode(stallCount, forKey: .stallCount)
        try container.encode(stallDurationMs, forKey: .stallDurationMs)
        try container.encode(maxStallDurationMs, forKey: .maxStallDurationMs)
        try container.encode(droppedFrames, forKey: .droppedFrames)
        try container.encode(bitrateKbps, forKey: .bitrateKbps)
        try container.encode(bufferLengthMs, forKey: .bufferLengthMs)
        try container.encode(liveLatencyMs, forKey: .liveLatencyMs)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
    }
}

private extension StringCodingKey {
    static let watchDurationMs: StringCodingKey = "watch_duration_ms"
    static let stallCount: StringCodingKey = "stall_count"
    static let stallDurationMs: StringCodingKey = "stall_duration_ms"
    static let maxStallDurationMs: StringCodingKey = "max_stall_duration_ms"
    static let droppedFrames: StringCodingKey = "dropped_frames"
    static let bitrateKbps: StringCodingKey = "bitrate_kbps"
    static let bufferLengthMs: StringCodingKey = "buffer_length_ms"
    static let liveLatencyMs: StringCodingKey = "live_latency_ms"
}
