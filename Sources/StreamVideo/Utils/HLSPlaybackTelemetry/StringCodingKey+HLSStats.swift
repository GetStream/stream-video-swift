//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension StringCodingKey {
    static let bitrateKbps: StringCodingKey = "bitrate_kbps"
    static let bufferLengthMs: StringCodingKey = "buffer_length_ms"
    static let droppedFrames: StringCodingKey = "dropped_frames"
    static let endReason: StringCodingKey = "end_reason"
    static let errorCode: StringCodingKey = "error_code"
    static let liveLatencyMs: StringCodingKey = "live_latency_ms"
    static let maxStallDurationMs: StringCodingKey = "max_stall_duration_ms"
    static let os: StringCodingKey = "os"
    static let osVersion: StringCodingKey = "os_version"
    static let stallCount: StringCodingKey = "stall_count"
    static let stallDurationMs: StringCodingKey = "stall_duration_ms"
    static let stats: StringCodingKey = "stats"
    static let unifiedSessionId: StringCodingKey = "unified_session_id"
    static let watchDurationMs: StringCodingKey = "watch_duration_ms"
}
