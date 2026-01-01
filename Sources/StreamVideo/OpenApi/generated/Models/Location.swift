//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class Location: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var continentCode: String
    public var countryIsoCode: String
    public var subdivisionIsoCode: String

    public init(continentCode: String, countryIsoCode: String, subdivisionIsoCode: String) {
        self.continentCode = continentCode
        self.countryIsoCode = countryIsoCode
        self.subdivisionIsoCode = subdivisionIsoCode
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case continentCode = "continent_code"
        case countryIsoCode = "country_iso_code"
        case subdivisionIsoCode = "subdivision_iso_code"
    }
    
    public static func == (lhs: Location, rhs: Location) -> Bool {
        lhs.continentCode == rhs.continentCode &&
            lhs.countryIsoCode == rhs.countryIsoCode &&
            lhs.subdivisionIsoCode == rhs.subdivisionIsoCode
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(continentCode)
        hasher.combine(countryIsoCode)
        hasher.combine(subdivisionIsoCode)
    }
}
