//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class CallParticipantResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var joinedAt: Date
    public var role: String
    public var user: UserResponse
    public var userSessionId: String

    public init(joinedAt: Date, role: String, user: UserResponse, userSessionId: String) {
        self.joinedAt = joinedAt
        self.role = role
        self.user = user
        self.userSessionId = userSessionId
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case joinedAt = "joined_at"
        case role
        case user
        case userSessionId = "user_session_id"
    }
    
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
