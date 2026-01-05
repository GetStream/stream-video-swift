//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class UnblockUserRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var userId: String

    public init(userId: String) {
        self.userId = userId
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case userId = "user_id"
    }
    
    public static func == (lhs: UnblockUserRequest, rhs: UnblockUserRequest) -> Bool {
        lhs.userId == rhs.userId
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(userId)
    }
}
