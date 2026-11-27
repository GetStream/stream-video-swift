//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class HLSPlaybackStats: Sendable, Encodable, JSONEncodable {
    public let bitrateKbps: Int
    public let bufferLengthMs: Int
    public let droppedFrames: Int
    public let height: Int
    public let liveLatencyMs: Int
    public let maxStallDurationMs: Int
    public let stallCount: Int
    public let stallDurationMs: Int
    public let watchDurationMs: Int
    public let width: Int

    public init(
        bitrateKbps: Int,
        bufferLengthMs: Int,
        droppedFrames: Int,
        height: Int,
        liveLatencyMs: Int,
        maxStallDurationMs: Int,
        stallCount: Int,
        stallDurationMs: Int,
        watchDurationMs: Int,
        width: Int
    ) {
        self.bitrateKbps = bitrateKbps
        self.bufferLengthMs = bufferLengthMs
        self.droppedFrames = droppedFrames
        self.height = height
        self.liveLatencyMs = liveLatencyMs
        self.maxStallDurationMs = maxStallDurationMs
        self.stallCount = stallCount
        self.stallDurationMs = stallDurationMs
        self.watchDurationMs = watchDurationMs
        self.width = width
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(bitrateKbps, forKey: .bitrateKbps)
        try container.encode(bufferLengthMs, forKey: .bufferLengthMs)
        try container.encode(droppedFrames, forKey: .droppedFrames)
        try container.encode(height, forKey: .height)
        try container.encode(liveLatencyMs, forKey: .liveLatencyMs)
        try container.encode(maxStallDurationMs, forKey: .maxStallDurationMs)
        try container.encode(stallCount, forKey: .stallCount)
        try container.encode(stallDurationMs, forKey: .stallDurationMs)
        try container.encode(watchDurationMs, forKey: .watchDurationMs)
        try container.encode(width, forKey: .width)
    }
}

extension HLSPlaybackStats: Hashable {
    public static func == (lhs: HLSPlaybackStats, rhs: HLSPlaybackStats) -> Bool {
        lhs.bitrateKbps == rhs.bitrateKbps &&
            lhs.bufferLengthMs == rhs.bufferLengthMs &&
            lhs.droppedFrames == rhs.droppedFrames &&
            lhs.height == rhs.height &&
            lhs.liveLatencyMs == rhs.liveLatencyMs &&
            lhs.maxStallDurationMs == rhs.maxStallDurationMs &&
            lhs.stallCount == rhs.stallCount &&
            lhs.stallDurationMs == rhs.stallDurationMs &&
            lhs.watchDurationMs == rhs.watchDurationMs &&
            lhs.width == rhs.width
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(bitrateKbps)
        hasher.combine(bufferLengthMs)
        hasher.combine(droppedFrames)
        hasher.combine(height)
        hasher.combine(liveLatencyMs)
        hasher.combine(maxStallDurationMs)
        hasher.combine(stallCount)
        hasher.combine(stallDurationMs)
        hasher.combine(watchDurationMs)
        hasher.combine(width)
    }
}
