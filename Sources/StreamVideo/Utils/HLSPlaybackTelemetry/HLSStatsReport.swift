//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// One playback report for `POST /video/call/{type}/{id}/hls_stats`.
struct HLSStatsReport: Encodable, Sendable, Equatable {
    var callSessionId: String
    var userSessionId: String
    var unifiedSessionId: String
    var type: String
    var timestamp: Int64
    var sdk: String
    var sdkVersion: String
    var os: String
    var osVersion: String
    var endReason: String?
    var errorCode: String?
    var stats: HLSPlaybackStats?
    var events: [HLSStatsEvent]

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(callSessionId, forKey: "call_session_id")
        try container.encode(userSessionId, forKey: "user_session_id")
        try container.encode(unifiedSessionId, forKey: "unified_session_id")
        try container.encode(type, forKey: "type")
        try container.encode(timestamp, forKey: "timestamp")
        try container.encode(sdk, forKey: "sdk")
        try container.encode(sdkVersion, forKey: "sdk_version")
        try container.encode(os, forKey: "os")
        try container.encode(osVersion, forKey: "os_version")
        try container.encodeIfPresent(endReason, forKey: "end_reason")
        try container.encodeIfPresent(errorCode, forKey: "error_code")
        try container.encodeIfPresent(stats, forKey: "stats")
        if !events.isEmpty {
            try container.encode(events, forKey: "events")
        }
    }
}

/// A full playback snapshot. The latest report replaces earlier ones.
struct HLSPlaybackStats: Encodable, Sendable, Equatable {
    var watchDurationMs: Int64 = 0
    var stallCount: Int = 0
    var stallDurationMs: Int64 = 0
    var maxStallDurationMs: Int64 = 0
    var droppedFrames: Int = 0
    var bitrateKbps: Int = 0
    var bufferLengthMs: Int = 0
    var liveLatencyMs: Int = 0
    var width: Int = 0
    var height: Int = 0

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(watchDurationMs, forKey: "watch_duration_ms")
        try container.encode(stallCount, forKey: "stall_count")
        try container.encode(stallDurationMs, forKey: "stall_duration_ms")
        try container.encode(maxStallDurationMs, forKey: "max_stall_duration_ms")
        try container.encode(droppedFrames, forKey: "dropped_frames")
        try container.encode(bitrateKbps, forKey: "bitrate_kbps")
        try container.encode(bufferLengthMs, forKey: "buffer_length_ms")
        try container.encode(liveLatencyMs, forKey: "live_latency_ms")
        try container.encode(width, forKey: "width")
        try container.encode(height, forKey: "height")
    }
}

/// A player event carried beside a report. `started`, `stats`, and `ended`
/// are report types, so they are not valid event types.
struct HLSStatsEvent: Encodable, Sendable, Equatable {
    var type: String
    var timestamp: Int64
    var data: [String: String]

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(type, forKey: "type")
        try container.encode(timestamp, forKey: "timestamp")
        if !data.isEmpty {
            try container.encode(data, forKey: "data")
        }
    }
}

struct HLSPlaybackMeasurement: Sendable, Equatable {
    var watchDurationMs: Int64 = 0
    var stallCount: Int = 0
    var stallDurationMs: Int64 = 0
    var maxStallDurationMs: Int64 = 0
    var droppedFrames: Int = 0
    var bitrateKbps: Int = 0
    var bufferLengthMs: Int = 0
    var liveLatencyMs: Int = 0
    var width: Int = 0
    var height: Int = 0
}

struct HLSPlaybackEvent: Sendable, Equatable {
    var type: String
    var timestamp: Int64
    var data: [String: String]
}

protocol HLSStatsSending: Sendable {
    func reportHLSStats(
        callType: String,
        callId: String,
        report: HLSStatsReport
    ) async throws
}
