//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class Coordinates: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var latitude: Float
    public var longitude: Float

    public init(latitude: Float, longitude: Float) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case latitude
        case longitude
    }
    
    public static func == (lhs: Coordinates, rhs: Coordinates) -> Bool {
        lhs.latitude == rhs.latitude &&
            lhs.longitude == rhs.longitude
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }
}
