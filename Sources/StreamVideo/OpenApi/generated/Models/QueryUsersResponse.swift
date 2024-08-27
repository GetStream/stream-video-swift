//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct QueryUsersResponse: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var duration: String
    public var users: [FullUserResponse]

    public init(duration: String, users: [FullUserResponse]) {
        self.duration = duration
        self.users = users
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case users
    }
}
