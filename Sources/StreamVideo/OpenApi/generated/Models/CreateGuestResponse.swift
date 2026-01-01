//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class CreateGuestResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var accessToken: String
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
