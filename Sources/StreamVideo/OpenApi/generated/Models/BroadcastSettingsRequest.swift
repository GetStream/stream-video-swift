//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class BroadcastSettingsRequest: @unchecked Sendable, Encodable, JSONEncodable {
    public var enabled: Bool?
    public var hls: HLSSettingsRequest?
    public var rtmp: RTMPSettingsRequest?

    public init(enabled: Bool? = nil, hls: HLSSettingsRequest? = nil, rtmp: RTMPSettingsRequest? = nil) {
        self.enabled = enabled
        self.hls = hls
        self.rtmp = rtmp
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(enabled, forKey: .enabled)
        try container.encodeIfPresent(hls, forKey: .hls)
        try container.encodeIfPresent(rtmp, forKey: .rtmp)
    }
}

extension BroadcastSettingsRequest: Hashable {
    public static func == (lhs: BroadcastSettingsRequest, rhs: BroadcastSettingsRequest) -> Bool {
        lhs.enabled == rhs.enabled &&
            lhs.hls == rhs.hls &&
            lhs.rtmp == rhs.rtmp
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(enabled)
        hasher.combine(hls)
        hasher.combine(rtmp)
    }
}
