//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class EdgeResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var continentCode: String
    public var countryIsoCode: String
    public var green: Int
    public var id: String
    public var latencyTestUrl: String
    public var latitude: Float
    public var longitude: Float
    public var red: Int
    public var subdivisionIsoCode: String
    public var yellow: Int

    public init(
        continentCode: String,
        countryIsoCode: String,
        green: Int,
        id: String,
        latencyTestUrl: String,
        latitude: Float,
        longitude: Float,
        red: Int,
        subdivisionIsoCode: String,
        yellow: Int
    ) {
        self.continentCode = continentCode
        self.countryIsoCode = countryIsoCode
        self.green = green
        self.id = id
        self.latencyTestUrl = latencyTestUrl
        self.latitude = latitude
        self.longitude = longitude
        self.red = red
        self.subdivisionIsoCode = subdivisionIsoCode
        self.yellow = yellow
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case continentCode = "continent_code"
        case countryIsoCode = "country_iso_code"
        case green
        case id
        case latencyTestUrl = "latency_test_url"
        case latitude
        case longitude
        case red
        case subdivisionIsoCode = "subdivision_iso_code"
        case yellow
    }
    
    public static func == (lhs: EdgeResponse, rhs: EdgeResponse) -> Bool {
        lhs.continentCode == rhs.continentCode &&
            lhs.countryIsoCode == rhs.countryIsoCode &&
            lhs.green == rhs.green &&
            lhs.id == rhs.id &&
            lhs.latencyTestUrl == rhs.latencyTestUrl &&
            lhs.latitude == rhs.latitude &&
            lhs.longitude == rhs.longitude &&
            lhs.red == rhs.red &&
            lhs.subdivisionIsoCode == rhs.subdivisionIsoCode &&
            lhs.yellow == rhs.yellow
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(continentCode)
        hasher.combine(countryIsoCode)
        hasher.combine(green)
        hasher.combine(id)
        hasher.combine(latencyTestUrl)
        hasher.combine(latitude)
        hasher.combine(longitude)
        hasher.combine(red)
        hasher.combine(subdivisionIsoCode)
        hasher.combine(yellow)
    }
}
