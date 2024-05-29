//
// GeolocationResult.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation


public struct GeolocationResult: Codable, JSONEncodable, Hashable {
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

    public init(accuracyRadius: Int, city: String, continent: String, continentCode: String, country: String, countryIsoCode: String, latitude: Float, longitude: Float, subdivision: String, subdivisionIsoCode: String) {
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

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(accuracyRadius, forKey: .accuracyRadius)
        try container.encode(city, forKey: .city)
        try container.encode(continent, forKey: .continent)
        try container.encode(continentCode, forKey: .continentCode)
        try container.encode(country, forKey: .country)
        try container.encode(countryIsoCode, forKey: .countryIsoCode)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(subdivision, forKey: .subdivision)
        try container.encode(subdivisionIsoCode, forKey: .subdivisionIsoCode)
    }
}

