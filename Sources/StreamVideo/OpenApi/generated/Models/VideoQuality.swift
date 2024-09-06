//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct VideoQuality: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var resolution: VideoResolution?
    public var usageType: String?

    public init(resolution: VideoResolution? = nil, usageType: String? = nil) {
        self.resolution = resolution
        self.usageType = usageType
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case resolution
        case usageType = "usage_type"
    }
}
