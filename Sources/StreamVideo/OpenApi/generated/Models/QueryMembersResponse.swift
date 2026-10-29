//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// Basic response information
public final class QueryMembersResponse: @unchecked Sendable, Codable, JSONEncodable {
    /// Duration of the request in milliseconds
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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.duration = try container.decode(String.self, forKey: .duration)
        self.members = try container.decode([MemberResponse].self, forKey: .members)
        self.next = try container.decodeIfPresent(String.self, forKey: .next)
        self.prev = try container.decodeIfPresent(String.self, forKey: .prev)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(duration, forKey: .duration)
        try container.encode(members, forKey: .members)
        try container.encodeIfPresent(next, forKey: .next)
        try container.encodeIfPresent(prev, forKey: .prev)
    }
}

extension QueryMembersResponse: Hashable {
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
