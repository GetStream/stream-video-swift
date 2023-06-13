//
// CreateGuestRequest.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif





public struct CreateGuestRequest: Codable, JSONEncodable, Hashable {

    public var user: UserRequest

    public init(user: UserRequest) {
        self.user = user
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case user
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(user, forKey: .user)
    }
}

