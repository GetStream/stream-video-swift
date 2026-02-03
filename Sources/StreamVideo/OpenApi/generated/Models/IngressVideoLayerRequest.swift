//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class IngressVideoLayerRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public enum IngressVideoLayerRequestCodec: String, Sendable, Codable, CaseIterable {
        case h264 = "h264"
        case vp8 = "vp8"
        case unknown = "_unknown"

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let decodedValue = try? container.decode(String.self),
                let value = Self(rawValue: decodedValue) {
                self = value
            } else {
                self = .unknown
            }
        }
    }
    public var bitrate: Int
    public var codec: IngressVideoLayerRequestCodec
    public var frameRateLimit: Int
    public var maxDimension: Int
    public var minDimension: Int

    public init(bitrate: Int, codec: IngressVideoLayerRequestCodec, frameRateLimit: Int, maxDimension: Int, minDimension: Int) {
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

    public static func == (lhs: IngressVideoLayerRequest, rhs: IngressVideoLayerRequest) -> Bool {
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
