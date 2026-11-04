//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class RingCallResponse: @unchecked Sendable, Codable, JSONEncodable {
    public var duration: String
    /// List of members ringing notification was sent to
    public var membersIds: [String]

    public init(duration: String, membersIds: [String]) {
        self.duration = duration
        self.membersIds = membersIds
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.duration = try container.decode(String.self, forKey: .duration)
        self.membersIds = try container.decode([String].self, forKey: .membersIds)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(duration, forKey: .duration)
        try container.encode(membersIds, forKey: .membersIds)
    }
}

extension RingCallResponse: Hashable {
    public static func == (lhs: RingCallResponse, rhs: RingCallResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.membersIds == rhs.membersIds
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(membersIds)
    }
}
