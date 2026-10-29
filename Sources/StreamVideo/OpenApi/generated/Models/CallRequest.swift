//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// CallRequest is the payload for creating a call.
public final class CallRequest: @unchecked Sendable, Codable, JSONEncodable {
    public var custom: [String: RawJSON]?
    public var members: [MemberRequest]?
    public var settingsOverride: CallSettingsRequest?
    public var startsAt: Date?
    public var team: String?
    public var video: Bool?

    public init(
        custom: [String: RawJSON]? = nil,
        members: [MemberRequest]? = nil,
        settingsOverride: CallSettingsRequest? = nil,
        startsAt: Date? = nil,
        team: String? = nil,
        video: Bool? = nil
    ) {
        self.custom = custom
        self.members = members
        self.settingsOverride = settingsOverride
        self.startsAt = startsAt
        self.team = team
        self.video = video
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.custom = try container.decodeIfPresent([String: RawJSON].self, forKey: .custom)
        self.members = try container.decodeIfPresent([MemberRequest].self, forKey: .members)
        self.settingsOverride = try container.decodeIfPresent(CallSettingsRequest.self, forKey: .settingsOverride)
        self.startsAt = try container.decodeIfPresent(Date.self, forKey: .startsAt)
        self.team = try container.decodeIfPresent(String.self, forKey: .team)
        self.video = try container.decodeIfPresent(Bool.self, forKey: .video)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(custom, forKey: .custom)
        try container.encodeIfPresent(members, forKey: .members)
        try container.encodeIfPresent(settingsOverride, forKey: .settingsOverride)
        try container.encodeIfPresent(startsAt, forKey: .startsAt)
        try container.encodeIfPresent(team, forKey: .team)
        try container.encodeIfPresent(video, forKey: .video)
    }
}

extension CallRequest: Hashable {
    public static func == (lhs: CallRequest, rhs: CallRequest) -> Bool {
        lhs.custom == rhs.custom &&
            lhs.members == rhs.members &&
            lhs.settingsOverride == rhs.settingsOverride &&
            lhs.startsAt == rhs.startsAt &&
            lhs.team == rhs.team &&
            lhs.video == rhs.video
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(custom)
        hasher.combine(members)
        hasher.combine(settingsOverride)
        hasher.combine(startsAt)
        hasher.combine(team)
        hasher.combine(video)
    }
}
