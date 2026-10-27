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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.removeMembers = try container.decodeIfPresent([String].self, forKey: .removeMembers)
        self.updateMembers = try container.decodeIfPresent([MemberRequest].self, forKey: .updateMembers)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(removeMembers, forKey: .removeMembers)
        try container.encodeIfPresent(updateMembers, forKey: .updateMembers)
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
