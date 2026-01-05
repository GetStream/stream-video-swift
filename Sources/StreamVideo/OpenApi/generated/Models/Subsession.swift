//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class Subsession: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var endedAt: Int
    public var joinedAt: Int
    public var pubSubHint: MediaPubSubHint?
    public var sfuId: String

    public init(endedAt: Int, joinedAt: Int, pubSubHint: MediaPubSubHint? = nil, sfuId: String) {
        self.endedAt = endedAt
        self.joinedAt = joinedAt
        self.pubSubHint = pubSubHint
        self.sfuId = sfuId
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case endedAt = "ended_at"
        case joinedAt = "joined_at"
        case pubSubHint = "pub_sub_hint"
        case sfuId = "sfu_id"
    }
    
    public static func == (lhs: Subsession, rhs: Subsession) -> Bool {
        lhs.endedAt == rhs.endedAt &&
            lhs.joinedAt == rhs.joinedAt &&
            lhs.pubSubHint == rhs.pubSubHint &&
            lhs.sfuId == rhs.sfuId
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(endedAt)
        hasher.combine(joinedAt)
        hasher.combine(pubSubHint)
        hasher.combine(sfuId)
    }
}
