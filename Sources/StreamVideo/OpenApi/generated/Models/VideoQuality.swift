//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class VideoQuality: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
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
    
    public static func == (lhs: VideoQuality, rhs: VideoQuality) -> Bool {
        lhs.resolution == rhs.resolution &&
            lhs.usageType == rhs.usageType
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(resolution)
        hasher.combine(usageType)
    }
}
