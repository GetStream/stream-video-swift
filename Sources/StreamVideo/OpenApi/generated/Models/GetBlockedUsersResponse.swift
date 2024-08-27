//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct GetBlockedUsersResponse: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var blocks: [BlockedUserResponse?]
    public var duration: String

    public init(blocks: [BlockedUserResponse?], duration: String) {
        self.blocks = blocks
        self.duration = duration
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case blocks
        case duration
    }
}
