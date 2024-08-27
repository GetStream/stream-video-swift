//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct UpdateUsersPartialRequest: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var users: [UpdateUserPartialRequest]

    public init(users: [UpdateUserPartialRequest]) {
        self.users = users
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case users
    }
}
