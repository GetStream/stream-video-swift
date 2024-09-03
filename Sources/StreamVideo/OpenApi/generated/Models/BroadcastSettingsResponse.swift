//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct BroadcastSettingsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
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
}
