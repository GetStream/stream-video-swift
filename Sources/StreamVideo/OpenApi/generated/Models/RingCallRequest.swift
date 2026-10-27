//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class RingCallRequest: @unchecked Sendable, Codable, JSONEncodable {
    /// Members that should receive the ring. If no ids are provided, all call members who are not already in the call will receive ring notifications.
    public var membersIds: [String]?
    /// Indicate if call should be video
    public var video: Bool?

    public init(membersIds: [String]? = nil, video: Bool? = nil) {
        self.membersIds = membersIds
        self.video = video
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.membersIds = try container.decodeIfPresent([String].self, forKey: .membersIds)
        self.video = try container.decodeIfPresent(Bool.self, forKey: .video)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(membersIds, forKey: .membersIds)
        try container.encodeIfPresent(video, forKey: .video)
    }
}

extension RingCallRequest: Hashable {
    public static func == (lhs: RingCallRequest, rhs: RingCallRequest) -> Bool {
        lhs.membersIds == rhs.membersIds &&
            lhs.video == rhs.video
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(membersIds)
        hasher.combine(video)
    }
}
