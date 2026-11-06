//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class IngressVideoLayerRequestCodec: RawRepresentable, Codable, CustomStringConvertible, Hashable, Sendable {
    public let rawValue: String

    public var description: String { rawValue }

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let h264 = IngressVideoLayerRequestCodec(rawValue: "h264")
    public static let vp8 = IngressVideoLayerRequestCodec(rawValue: "vp8")
}

public final class IngressVideoLayerRequest: Sendable, Encodable, JSONEncodable {
    public let bitrate: Int
    public let codec: IngressVideoLayerRequestCodec
    public let frameRateLimit: Int
    public let maxDimension: Int
    public let minDimension: Int

    public init(bitrate: Int, codec: IngressVideoLayerRequestCodec, frameRateLimit: Int, maxDimension: Int, minDimension: Int) {
        self.bitrate = bitrate
        self.codec = codec
        self.frameRateLimit = frameRateLimit
        self.maxDimension = maxDimension
        self.minDimension = minDimension
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

extension IngressVideoLayerRequest: Hashable {
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
