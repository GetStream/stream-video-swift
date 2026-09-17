//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class UpdateCallMembersRequest: @unchecked Sendable, Encodable, JSONEncodable, Hashable {
    
    public var removeMembers: [String]?
    public var updateMembers: [MemberRequest]?

    public init(removeMembers: [String]? = nil, updateMembers: [MemberRequest]? = nil) {
        self.removeMembers = removeMembers
        self.updateMembers = updateMembers
    }
    
    public enum CodingKeys: String, CodingKey {
        case removeMembers = "remove_members"
        case updateMembers = "update_members"
    }
    
    public static func == (lhs: UpdateCallMembersRequest, rhs: UpdateCallMembersRequest) -> Bool {
        lhs.removeMembers == rhs.removeMembers &&
            lhs.updateMembers == rhs.updateMembers
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(removeMembers)
        hasher.combine(updateMembers)
    }
}
