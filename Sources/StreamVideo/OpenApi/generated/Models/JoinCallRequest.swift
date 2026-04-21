//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class JoinCallRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// if true the call will be created if it doesn't exist
    public var create: Bool?
    public var data: CallRequest?
    /// if true, the participant will be marked as publsihing to large audience
    public var hintHighScaleLivestreamPublisher: Bool?
    public var location: String
    public var membersLimit: Int?
    /// If the participant is migrating from another SFU, then this is the ID of the previous SFU
    public var migratingFrom: String?
    /// List of SFU IDs to exclude when picking a new SFU for the participant
    public var migratingFromList: [String]?
    public var notify: Bool?
    /// if true and the call is created, the notification will include ring=true
    public var ring: Bool?
    public var video: Bool?

    public init(
        create: Bool? = nil,
        data: CallRequest? = nil,
        hintHighScaleLivestreamPublisher: Bool? = nil,
        location: String,
        membersLimit: Int? = nil,
        migratingFrom: String? = nil,
        migratingFromList: [String]? = nil,
        notify: Bool? = nil,
        ring: Bool? = nil,
        video: Bool? = nil
    ) {
        self.create = create
        self.data = data
        self.hintHighScaleLivestreamPublisher = hintHighScaleLivestreamPublisher
        self.location = location
        self.membersLimit = membersLimit
        self.migratingFrom = migratingFrom
        self.migratingFromList = migratingFromList
        self.notify = notify
        self.ring = ring
        self.video = video
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case create
        case data
        case hintHighScaleLivestreamPublisher = "hint_high_scale_livestream_publisher"
        case location
        case membersLimit = "members_limit"
        case migratingFrom = "migrating_from"
        case migratingFromList = "migrating_from_list"
        case notify
        case ring
        case video
    }

    public static func == (lhs: JoinCallRequest, rhs: JoinCallRequest) -> Bool {
        lhs.create == rhs.create &&
            lhs.data == rhs.data &&
            lhs.hintHighScaleLivestreamPublisher == rhs.hintHighScaleLivestreamPublisher &&
            lhs.location == rhs.location &&
            lhs.membersLimit == rhs.membersLimit &&
            lhs.migratingFrom == rhs.migratingFrom &&
            lhs.migratingFromList == rhs.migratingFromList &&
            lhs.notify == rhs.notify &&
            lhs.ring == rhs.ring &&
            lhs.video == rhs.video
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(create)
        hasher.combine(data)
        hasher.combine(hintHighScaleLivestreamPublisher)
        hasher.combine(location)
        hasher.combine(membersLimit)
        hasher.combine(migratingFrom)
        hasher.combine(migratingFromList)
        hasher.combine(notify)
        hasher.combine(ring)
        hasher.combine(video)
    }
}
