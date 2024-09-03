//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct Subsession: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var endedAt: Int
    public var joinedAt: Int
    public var pubSubHint: MediaPubSubHint? = nil
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
}
