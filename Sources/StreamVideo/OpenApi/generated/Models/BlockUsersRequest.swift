//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct BlockUsersRequest: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var blockedUserId: String

    public init(blockedUserId: String) {
        self.blockedUserId = blockedUserId
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case blockedUserId = "blocked_user_id"
    }
}
