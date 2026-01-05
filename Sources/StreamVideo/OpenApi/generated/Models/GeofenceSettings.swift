//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class GeofenceSettings: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var names: [String]

    public init(names: [String]) {
        self.names = names
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case names
    }
    
    public static func == (lhs: GeofenceSettings, rhs: GeofenceSettings) -> Bool {
        lhs.names == rhs.names
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(names)
    }
}
