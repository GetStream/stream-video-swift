//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct UpdateUsersRequest: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var users: [String: UserRequest]

    public init(users: [String: UserRequest]) {
        self.users = users
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case users
    }
}
