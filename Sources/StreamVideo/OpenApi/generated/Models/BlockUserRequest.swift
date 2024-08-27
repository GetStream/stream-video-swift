//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct BlockUserRequest: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var userId: String

    public init(userId: String) {
        self.userId = userId
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case userId = "user_id"
    }
}
