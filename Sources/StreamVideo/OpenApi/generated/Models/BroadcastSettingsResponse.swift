//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// BroadcastSettingsResponse is the payload for broadcasting settings
public final class BroadcastSettingsResponse: @unchecked Sendable, Codable, JSONEncodable {
    public var enabled: Bool
    /// HLSSettings is the payload for HLS settings
    public var hls: HLSSettingsResponse
    /// RTMPSettingsResponse is the payload for RTMP settings
    public var rtmp: RTMPSettingsResponse

    public init(enabled: Bool, hls: HLSSettingsResponse, rtmp: RTMPSettingsResponse) {
        self.enabled = enabled
        self.hls = hls
        self.rtmp = rtmp
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.enabled = try container.decode(Bool.self, forKey: .enabled)
        self.hls = try container.decode(HLSSettingsResponse.self, forKey: .hls)
        self.rtmp = try container.decode(RTMPSettingsResponse.self, forKey: .rtmp)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(enabled, forKey: .enabled)
        try container.encode(hls, forKey: .hls)
        try container.encode(rtmp, forKey: .rtmp)
    }
}

extension BroadcastSettingsResponse: Hashable {
    public static func == (lhs: BroadcastSettingsResponse, rhs: BroadcastSettingsResponse) -> Bool {
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
