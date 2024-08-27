//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct SFULocationResponse: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
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
}
