//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct EdgeResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var continentCode: String
    public var countryIsoCode: String
    public var green: Int
    public var id: String
    public var latencyTestUrl: String
    public var latitude: Double
    public var longitude: Double
    public var red: Int
    public var subdivisionIsoCode: String
    public var yellow: Int

    public init(
        continentCode: String,
        countryIsoCode: String,
        green: Int,
        id: String,
        latencyTestUrl: String,
        latitude: Double,
        longitude: Double,
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
}
