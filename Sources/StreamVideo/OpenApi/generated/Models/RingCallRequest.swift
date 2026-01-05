//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class RingCallRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    public var membersIds: [String]?
    public var video: Bool?

    public init(membersIds: [String]? = nil, video: Bool? = nil) {
        self.membersIds = membersIds
        self.video = video
    }

public enum CodingKeys: String, CodingKey, CaseIterable {
    case membersIds = "members_ids"
    case video
}

    public static func == (lhs: RingCallRequest, rhs: RingCallRequest) -> Bool {
        lhs.membersIds == rhs.membersIds &&
        lhs.video == rhs.video
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(membersIds)
        hasher.combine(video)
    }
}
