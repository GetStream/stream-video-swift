//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class QueryMembersResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var duration: String
    public var members: [MemberResponse]
    public var next: String?
    public var prev: String?

    public init(duration: String, members: [MemberResponse], next: String? = nil, prev: String? = nil) {
        self.duration = duration
        self.members = members
        self.next = next
        self.prev = prev
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case members
        case next
        case prev
    }
    
    public static func == (lhs: QueryMembersResponse, rhs: QueryMembersResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.members == rhs.members &&
            lhs.next == rhs.next &&
            lhs.prev == rhs.prev
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(members)
        hasher.combine(next)
        hasher.combine(prev)
    }
}
