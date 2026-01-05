//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class GeolocationResult: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var accuracyRadius: Int
    public var city: String
    public var continent: String
    public var continentCode: String
    public var country: String
    public var countryIsoCode: String
    public var latitude: Float
    public var longitude: Float
    public var subdivision: String
    public var subdivisionIsoCode: String

    public init(
        accuracyRadius: Int,
        city: String,
        continent: String,
        continentCode: String,
        country: String,
        countryIsoCode: String,
        latitude: Float,
        longitude: Float,
        subdivision: String,
        subdivisionIsoCode: String
    ) {
        self.accuracyRadius = accuracyRadius
        self.city = city
        self.continent = continent
        self.continentCode = continentCode
        self.country = country
        self.countryIsoCode = countryIsoCode
        self.latitude = latitude
        self.longitude = longitude
        self.subdivision = subdivision
        self.subdivisionIsoCode = subdivisionIsoCode
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case accuracyRadius = "accuracy_radius"
        case city
        case continent
        case continentCode = "continent_code"
        case country
        case countryIsoCode = "country_iso_code"
        case latitude
        case longitude
        case subdivision
        case subdivisionIsoCode = "subdivision_iso_code"
    }
    
    public static func == (lhs: GeolocationResult, rhs: GeolocationResult) -> Bool {
        lhs.accuracyRadius == rhs.accuracyRadius &&
            lhs.city == rhs.city &&
            lhs.continent == rhs.continent &&
            lhs.continentCode == rhs.continentCode &&
            lhs.country == rhs.country &&
            lhs.countryIsoCode == rhs.countryIsoCode &&
            lhs.latitude == rhs.latitude &&
            lhs.longitude == rhs.longitude &&
            lhs.subdivision == rhs.subdivision &&
            lhs.subdivisionIsoCode == rhs.subdivisionIsoCode
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(accuracyRadius)
        hasher.combine(city)
        hasher.combine(continent)
        hasher.combine(continentCode)
        hasher.combine(country)
        hasher.combine(countryIsoCode)
        hasher.combine(latitude)
        hasher.combine(longitude)
        hasher.combine(subdivision)
        hasher.combine(subdivisionIsoCode)
    }
}
