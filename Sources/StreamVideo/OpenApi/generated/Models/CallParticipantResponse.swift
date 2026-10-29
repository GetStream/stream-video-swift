//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class CallParticipantResponse: @unchecked Sendable, Codable, JSONEncodable {
    public var joinedAt: Date
    public var role: String
    /// User response object
    public var user: UserResponse
    public var userSessionId: String

    public init(joinedAt: Date, role: String, user: UserResponse, userSessionId: String) {
        self.joinedAt = joinedAt
        self.role = role
        self.user = user
        self.userSessionId = userSessionId
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.joinedAt = try container.decode(Date.self, forKey: .joinedAt)
        self.role = try container.decode(String.self, forKey: .role)
        self.user = try container.decode(UserResponse.self, forKey: .user)
        self.userSessionId = try container.decode(String.self, forKey: .userSessionId)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(joinedAt, forKey: .joinedAt)
        try container.encode(role, forKey: .role)
        try container.encode(user, forKey: .user)
        try container.encode(userSessionId, forKey: .userSessionId)
    }
}

extension CallParticipantResponse: Hashable {
    public static func == (lhs: CallParticipantResponse, rhs: CallParticipantResponse) -> Bool {
        lhs.joinedAt == rhs.joinedAt &&
            lhs.role == rhs.role &&
            lhs.user == rhs.user &&
            lhs.userSessionId == rhs.userSessionId
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(joinedAt)
        hasher.combine(role)
        hasher.combine(user)
        hasher.combine(userSessionId)
    }
}
