//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class IngressVideoLayerResponse: @unchecked Sendable, Codable, JSONEncodable {
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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.bitrate = try container.decode(Int.self, forKey: .bitrate)
        self.codec = try container.decode(String.self, forKey: .codec)
        self.frameRateLimit = try container.decode(Int.self, forKey: .frameRateLimit)
        self.maxDimension = try container.decode(Int.self, forKey: .maxDimension)
        self.minDimension = try container.decode(Int.self, forKey: .minDimension)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(bitrate, forKey: .bitrate)
        try container.encode(codec, forKey: .codec)
        try container.encode(frameRateLimit, forKey: .frameRateLimit)
        try container.encode(maxDimension, forKey: .maxDimension)
        try container.encode(minDimension, forKey: .minDimension)
    }
}

extension IngressVideoLayerResponse: Hashable {
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
