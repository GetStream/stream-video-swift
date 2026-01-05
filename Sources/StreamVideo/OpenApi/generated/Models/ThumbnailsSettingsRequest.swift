//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class ThumbnailsSettingsRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var enabled: Bool?

    public init(enabled: Bool? = nil) {
        self.enabled = enabled
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case enabled
    }
    
    public static func == (lhs: ThumbnailsSettingsRequest, rhs: ThumbnailsSettingsRequest) -> Bool {
        lhs.enabled == rhs.enabled
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(enabled)
    }
}
