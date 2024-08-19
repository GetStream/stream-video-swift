//
// CreateGuestResponse.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation


public struct CreateGuestResponse: Codable, JSONEncodable, Hashable {
    /** the access token to authenticate the user */
    public var accessToken: String
    /** Duration of the request in milliseconds */
    public var duration: String
    public var user: UserResponse

    public init(accessToken: String, duration: String, user: UserResponse) {
        self.accessToken = accessToken
        self.duration = duration
        self.user = user
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case accessToken = "access_token"
        case duration
        case user
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(accessToken, forKey: .accessToken)
        try container.encode(duration, forKey: .duration)
        try container.encode(user, forKey: .user)
    }
}

