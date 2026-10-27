//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// Basic response information
public final class UpdateCallMembersResponse: @unchecked Sendable, Codable, JSONEncodable {
    /// Duration of the request in milliseconds
    public var duration: String
    public var members: [MemberResponse]

    public init(duration: String, members: [MemberResponse]) {
        self.duration = duration
        self.members = members
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.duration = try container.decode(String.self, forKey: .duration)
        self.members = try container.decode([MemberResponse].self, forKey: .members)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(duration, forKey: .duration)
        try container.encode(members, forKey: .members)
    }
}

extension UpdateCallMembersResponse: Hashable {
    public static func == (lhs: UpdateCallMembersResponse, rhs: UpdateCallMembersResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.members == rhs.members
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(members)
    }
}
