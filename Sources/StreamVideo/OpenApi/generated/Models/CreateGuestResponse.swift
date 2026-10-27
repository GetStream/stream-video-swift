//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class CreateGuestResponse: @unchecked Sendable, Codable, JSONEncodable {
    /// the access token to authenticate the user
    public var accessToken: String
    /// Duration of the request in milliseconds
    public var duration: String
    /// User response object
    public var user: UserResponse

    public init(accessToken: String, duration: String, user: UserResponse) {
        self.accessToken = accessToken
        self.duration = duration
        self.user = user
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.accessToken = try container.decode(String.self, forKey: .accessToken)
        self.duration = try container.decode(String.self, forKey: .duration)
        self.user = try container.decode(UserResponse.self, forKey: .user)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(accessToken, forKey: .accessToken)
        try container.encode(duration, forKey: .duration)
        try container.encode(user, forKey: .user)
    }
}

extension CreateGuestResponse: Hashable {
    public static func == (lhs: CreateGuestResponse, rhs: CreateGuestResponse) -> Bool {
        lhs.accessToken == rhs.accessToken &&
            lhs.duration == rhs.duration &&
            lhs.user == rhs.user
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(accessToken)
        hasher.combine(duration)
        hasher.combine(user)
    }
}
