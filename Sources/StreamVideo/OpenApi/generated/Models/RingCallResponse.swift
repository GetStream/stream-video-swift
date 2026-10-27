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

    public enum CodingKeys: String, CodingKey {
        case duration
        case membersIds = "members_ids"
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
