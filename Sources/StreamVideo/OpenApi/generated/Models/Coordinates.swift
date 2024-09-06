//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct Coordinates: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
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
}
