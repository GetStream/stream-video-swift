//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class RingCallResponse: @unchecked Sendable, Decodable {
    public var duration: String
    /// List of members ringing notification was sent to
    public var membersIds: [String]
    /// The ring this call created, for correlating the accept, reject and missed outcomes that follow
    public var ringId: String?

    public init(duration: String, membersIds: [String], ringId: String? = nil) {
        self.duration = duration
        self.membersIds = membersIds
        self.ringId = ringId
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.duration = try container.decode(String.self, forKey: .duration)
        self.membersIds = try container.decode([String].self, forKey: .membersIds)
        self.ringId = try container.decodeIfPresent(String.self, forKey: .ringId)
    }
}

extension RingCallResponse: Hashable {
    public static func == (lhs: RingCallResponse, rhs: RingCallResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.membersIds == rhs.membersIds &&
            lhs.ringId == rhs.ringId
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(membersIds)
        hasher.combine(ringId)
    }
}
