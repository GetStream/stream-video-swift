//
// Location.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation


public struct Location: Codable, JSONEncodable, Hashable {
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

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(continentCode, forKey: .continentCode)
        try container.encode(countryIsoCode, forKey: .countryIsoCode)
        try container.encode(subdivisionIsoCode, forKey: .subdivisionIsoCode)
    }
}

