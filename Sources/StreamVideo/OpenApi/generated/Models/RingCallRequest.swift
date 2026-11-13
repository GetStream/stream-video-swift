//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class RingCallRequest: Sendable, Encodable, JSONEncodable {
    /// Opaque context stored on the ring attempt; refs and IDs only
    public let custom: [String: RawJSON]?
    /// Members that should receive the ring. If no ids are provided, all call members who are not already in the call will receive ring notifications.
    public let membersIds: [String]?
    /// Indicate if call should be video
    public let video: Bool?

    public init(custom: [String: RawJSON]? = nil, membersIds: [String]? = nil, video: Bool? = nil) {
        self.custom = custom
        self.membersIds = membersIds
        self.video = video
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(custom, forKey: .custom)
        try container.encodeIfPresent(membersIds, forKey: .membersIds)
        try container.encodeIfPresent(video, forKey: .video)
    }
}

extension RingCallRequest: Hashable {
    public static func == (lhs: RingCallRequest, rhs: RingCallRequest) -> Bool {
        lhs.custom == rhs.custom &&
            lhs.membersIds == rhs.membersIds &&
            lhs.video == rhs.video
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(custom)
        hasher.combine(membersIds)
        hasher.combine(video)
    }
}
