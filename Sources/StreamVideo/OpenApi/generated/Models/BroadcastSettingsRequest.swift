//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct BroadcastSettingsRequest: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var enabled: Bool? = nil
    public var hls: HLSSettingsRequest? = nil

    public init(enabled: Bool? = nil, hls: HLSSettingsRequest? = nil) {
        self.enabled = enabled
        self.hls = hls
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case enabled
        case hls
    }
}
