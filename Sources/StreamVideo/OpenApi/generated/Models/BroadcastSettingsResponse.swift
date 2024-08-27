//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct BroadcastSettingsResponse: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var enabled: Bool
    public var hls: HLSSettingsResponse

    public init(enabled: Bool, hls: HLSSettingsResponse) {
        self.enabled = enabled
        self.hls = hls
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case enabled
        case hls
    }
}
