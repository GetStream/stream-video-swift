//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct UpdateUsersResponse: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var duration: String
    public var membershipDeletionTaskId: String
    public var users: [String: FullUserResponse]

    public init(duration: String, membershipDeletionTaskId: String, users: [String: FullUserResponse]) {
        self.duration = duration
        self.membershipDeletionTaskId = membershipDeletionTaskId
        self.users = users
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case membershipDeletionTaskId = "membership_deletion_task_id"
        case users
    }
}
