//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class IngressVideoLayerResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    public var bitrate: Int
    public var codec: String
    public var frameRateLimit: Int
    public var maxDimension: Int
    public var minDimension: Int

    public init(bitrate: Int, codec: String, frameRateLimit: Int, maxDimension: Int, minDimension: Int) {
        self.bitrate = bitrate
        self.codec = codec
        self.frameRateLimit = frameRateLimit
        self.maxDimension = maxDimension
        self.minDimension = minDimension
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case bitrate
        case codec
        case frameRateLimit = "frame_rate_limit"
        case maxDimension = "max_dimension"
        case minDimension = "min_dimension"
    }

    public static func == (lhs: IngressVideoLayerResponse, rhs: IngressVideoLayerResponse) -> Bool {
        lhs.bitrate == rhs.bitrate &&
        lhs.codec == rhs.codec &&
        lhs.frameRateLimit == rhs.frameRateLimit &&
        lhs.maxDimension == rhs.maxDimension &&
        lhs.minDimension == rhs.minDimension
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(bitrate)
        hasher.combine(codec)
        hasher.combine(frameRateLimit)
        hasher.combine(maxDimension)
        hasher.combine(minDimension)
    }
}
