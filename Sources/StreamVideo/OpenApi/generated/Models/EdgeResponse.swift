//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class EdgeResponse: @unchecked Sendable, Decodable {
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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.continentCode = try container.decode(String.self, forKey: .continentCode)
        self.countryIsoCode = try container.decode(String.self, forKey: .countryIsoCode)
        self.green = try container.decode(Int.self, forKey: .green)
        self.id = try container.decode(String.self, forKey: .id)
        self.latencyTestUrl = try container.decode(String.self, forKey: .latencyTestUrl)
        self.latitude = try container.decode(Float.self, forKey: .latitude)
        self.longitude = try container.decode(Float.self, forKey: .longitude)
        self.red = try container.decode(Int.self, forKey: .red)
        self.subdivisionIsoCode = try container.decode(String.self, forKey: .subdivisionIsoCode)
        self.yellow = try container.decode(Int.self, forKey: .yellow)
    }
}

extension EdgeResponse: Hashable {
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
