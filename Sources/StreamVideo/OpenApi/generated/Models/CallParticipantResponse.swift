//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct CallParticipantResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
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
}
