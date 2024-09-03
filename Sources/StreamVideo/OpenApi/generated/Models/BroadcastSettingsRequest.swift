//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct BroadcastSettingsRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var enabled: Bool? = nil
    public var hls: HLSSettingsRequest? = nil
    public var rtmp: RTMPSettingsRequest? = nil

    public init(enabled: Bool? = nil, hls: HLSSettingsRequest? = nil, rtmp: RTMPSettingsRequest? = nil) {
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
