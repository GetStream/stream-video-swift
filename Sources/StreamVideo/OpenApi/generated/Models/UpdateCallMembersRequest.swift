//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// Update call members
public final class UpdateCallMembersRequest: @unchecked Sendable, Codable, JSONEncodable {
    /// List of userID to remove
    public var removeMembers: [String]?
    /// List of members to update or insert
    public var updateMembers: [MemberRequest]?

    public init(removeMembers: [String]? = nil, updateMembers: [MemberRequest]? = nil) {
        self.removeMembers = removeMembers
        self.updateMembers = updateMembers
    }

    public enum CodingKeys: String, CodingKey {
        case removeMembers = "remove_members"
        case updateMembers = "update_members"
    }
}

extension UpdateCallMembersRequest: Hashable {
    public static func == (lhs: UpdateCallMembersRequest, rhs: UpdateCallMembersRequest) -> Bool {
        lhs.removeMembers == rhs.removeMembers &&
            lhs.updateMembers == rhs.updateMembers
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(removeMembers)
        hasher.combine(updateMembers)
    }
}
