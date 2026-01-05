//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class SFULocationResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var coordinates: Coordinates
    public var datacenter: String
    public var id: String
    public var location: Location

    public init(coordinates: Coordinates, datacenter: String, id: String, location: Location) {
        self.coordinates = coordinates
        self.datacenter = datacenter
        self.id = id
        self.location = location
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case coordinates
        case datacenter
        case id
        case location
    }
    
    public static func == (lhs: SFULocationResponse, rhs: SFULocationResponse) -> Bool {
        lhs.coordinates == rhs.coordinates &&
            lhs.datacenter == rhs.datacenter &&
            lhs.id == rhs.id &&
            lhs.location == rhs.location
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(coordinates)
        hasher.combine(datacenter)
        hasher.combine(id)
        hasher.combine(location)
    }
}
