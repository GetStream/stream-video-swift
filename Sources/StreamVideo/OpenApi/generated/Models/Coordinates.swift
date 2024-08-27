//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct Coordinates: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var latitude: Double
    public var longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case latitude
        case longitude
    }
}
