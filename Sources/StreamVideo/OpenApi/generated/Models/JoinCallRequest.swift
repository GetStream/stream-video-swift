//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class JoinCallRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var create: Bool?
    public var data: CallRequest?
    public var location: String
    public var membersLimit: Int?
    public var migratingFrom: String?
    public var notify: Bool?
    public var ring: Bool?
    public var video: Bool?

    public init(
        create: Bool? = nil,
        data: CallRequest? = nil,
        location: String,
        membersLimit: Int? = nil,
        migratingFrom: String? = nil,
        notify: Bool? = nil,
        ring: Bool? = nil,
        video: Bool? = nil
    ) {
        self.create = create
        self.data = data
        self.location = location
        self.membersLimit = membersLimit
        self.migratingFrom = migratingFrom
        self.notify = notify
        self.ring = ring
        self.video = video
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case create
        case data
        case location
        case membersLimit = "members_limit"
        case migratingFrom = "migrating_from"
        case notify
        case ring
        case video
    }
    
    public static func == (lhs: JoinCallRequest, rhs: JoinCallRequest) -> Bool {
        lhs.create == rhs.create &&
            lhs.data == rhs.data &&
            lhs.location == rhs.location &&
            lhs.membersLimit == rhs.membersLimit &&
            lhs.migratingFrom == rhs.migratingFrom &&
            lhs.notify == rhs.notify &&
            lhs.ring == rhs.ring &&
            lhs.video == rhs.video
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(create)
        hasher.combine(data)
        hasher.combine(location)
        hasher.combine(membersLimit)
        hasher.combine(migratingFrom)
        hasher.combine(notify)
        hasher.combine(ring)
        hasher.combine(video)
    }
}
