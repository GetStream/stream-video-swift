//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class IngressAudioEncodingOptionsRequest: Sendable, Encodable, JSONEncodable {
    public let bitrate: Int
    public let channels: Int
    public let enableDtx: Bool?

    public init(bitrate: Int, channels: Int, enableDtx: Bool? = nil) {
        self.bitrate = bitrate
        self.channels = channels
        self.enableDtx = enableDtx
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(bitrate, forKey: .bitrate)
        try container.encode(channels, forKey: .channels)
        try container.encodeIfPresent(enableDtx, forKey: .enableDtx)
    }
}

extension IngressAudioEncodingOptionsRequest: Hashable {
    public static func == (lhs: IngressAudioEncodingOptionsRequest, rhs: IngressAudioEncodingOptionsRequest) -> Bool {
        lhs.bitrate == rhs.bitrate &&
            lhs.channels == rhs.channels &&
            lhs.enableDtx == rhs.enableDtx
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(bitrate)
        hasher.combine(channels)
        hasher.combine(enableDtx)
    }
}
