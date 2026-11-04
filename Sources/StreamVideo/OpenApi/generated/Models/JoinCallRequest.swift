//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class JoinCallRequest: @unchecked Sendable, Codable, JSONEncodable {
    /// if true the call will be created if it doesn't exist
    public var create: Bool?
    /// CallRequest is the payload for creating a call.
    public var data: CallRequest?
    /// the encryption mode the client intends to use for this join; the join is rejected if it does not match the call's encryption configuration
    public var e2ee: Bool?
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
        e2ee: Bool? = nil,
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
        self.e2ee = e2ee
        self.hintHighScaleLivestreamPublisher = hintHighScaleLivestreamPublisher
        self.location = location
        self.membersLimit = membersLimit
        self.migratingFrom = migratingFrom
        self.migratingFromList = migratingFromList
        self.notify = notify
        self.ring = ring
        self.video = video
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.create = try container.decodeIfPresent(Bool.self, forKey: .create)
        self.data = try container.decodeIfPresent(CallRequest.self, forKey: .data)
        self.e2ee = try container.decodeIfPresent(Bool.self, forKey: .e2ee)
        self.hintHighScaleLivestreamPublisher = try container.decodeIfPresent(Bool.self, forKey: .hintHighScaleLivestreamPublisher)
        self.location = try container.decode(String.self, forKey: .location)
        self.membersLimit = try container.decodeIfPresent(Int.self, forKey: .membersLimit)
        self.migratingFrom = try container.decodeIfPresent(String.self, forKey: .migratingFrom)
        self.migratingFromList = try container.decodeIfPresent([String].self, forKey: .migratingFromList)
        self.notify = try container.decodeIfPresent(Bool.self, forKey: .notify)
        self.ring = try container.decodeIfPresent(Bool.self, forKey: .ring)
        self.video = try container.decodeIfPresent(Bool.self, forKey: .video)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(create, forKey: .create)
        try container.encodeIfPresent(data, forKey: .data)
        try container.encodeIfPresent(e2ee, forKey: .e2ee)
        try container.encodeIfPresent(hintHighScaleLivestreamPublisher, forKey: .hintHighScaleLivestreamPublisher)
        try container.encode(location, forKey: .location)
        try container.encodeIfPresent(membersLimit, forKey: .membersLimit)
        try container.encodeIfPresent(migratingFrom, forKey: .migratingFrom)
        try container.encodeIfPresent(migratingFromList, forKey: .migratingFromList)
        try container.encodeIfPresent(notify, forKey: .notify)
        try container.encodeIfPresent(ring, forKey: .ring)
        try container.encodeIfPresent(video, forKey: .video)
    }
}

extension JoinCallRequest: Hashable {
    public static func == (lhs: JoinCallRequest, rhs: JoinCallRequest) -> Bool {
        lhs.create == rhs.create &&
            lhs.data == rhs.data &&
            lhs.e2ee == rhs.e2ee &&
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
        hasher.combine(e2ee)
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
