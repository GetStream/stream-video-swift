//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class GeofenceSettingsRequest: @unchecked Sendable, Encodable, JSONEncodable, Hashable {
    
    public var names: [String]?

    public init(names: [String]? = nil) {
        self.names = names
    }
    
    public enum CodingKeys: String, CodingKey {
        case names
    }
    
    public static func == (lhs: GeofenceSettingsRequest, rhs: GeofenceSettingsRequest) -> Bool {
        lhs.names == rhs.names
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(names)
    }
}
