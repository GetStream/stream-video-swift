//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct RTMPSettingsRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var enabled: Bool?
    public var quality: String?

    public init(enabled: Bool? = nil, quality: String? = nil) {
        self.enabled = enabled
        self.quality = quality
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case enabled
        case quality
    }
}
