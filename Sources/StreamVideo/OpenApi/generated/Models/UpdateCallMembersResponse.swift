//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class UpdateCallMembersResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var duration: String
    public var members: [MemberResponse]

    public init(duration: String, members: [MemberResponse]) {
        self.duration = duration
        self.members = members
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case members
    }
    
    public static func == (lhs: UpdateCallMembersResponse, rhs: UpdateCallMembersResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.members == rhs.members
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(members)
    }
}
