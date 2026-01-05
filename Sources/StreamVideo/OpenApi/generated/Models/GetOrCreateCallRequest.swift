//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class GetOrCreateCallRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var data: CallRequest?
    public var membersLimit: Int?
    public var notify: Bool?
    public var ring: Bool?
    public var video: Bool?

    public init(data: CallRequest? = nil, membersLimit: Int? = nil, notify: Bool? = nil, ring: Bool? = nil, video: Bool? = nil) {
        self.data = data
        self.membersLimit = membersLimit
        self.notify = notify
        self.ring = ring
        self.video = video
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case data
        case membersLimit = "members_limit"
        case notify
        case ring
        case video
    }
    
    public static func == (lhs: GetOrCreateCallRequest, rhs: GetOrCreateCallRequest) -> Bool {
        lhs.data == rhs.data &&
            lhs.membersLimit == rhs.membersLimit &&
            lhs.notify == rhs.notify &&
            lhs.ring == rhs.ring &&
            lhs.video == rhs.video
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(data)
        hasher.combine(membersLimit)
        hasher.combine(notify)
        hasher.combine(ring)
        hasher.combine(video)
    }
}
