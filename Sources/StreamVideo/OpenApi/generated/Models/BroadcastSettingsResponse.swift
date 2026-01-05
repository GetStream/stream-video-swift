//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class BroadcastSettingsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var enabled: Bool
    public var hls: HLSSettingsResponse
    public var rtmp: RTMPSettingsResponse

    public init(enabled: Bool, hls: HLSSettingsResponse, rtmp: RTMPSettingsResponse) {
        self.enabled = enabled
        self.hls = hls
        self.rtmp = rtmp
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case enabled
        case hls
        case rtmp
    }
    
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
