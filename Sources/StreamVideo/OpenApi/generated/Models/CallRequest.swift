//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class CallRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
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
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case custom
        case members
        case settingsOverride = "settings_override"
        case startsAt = "starts_at"
        case team
        case video
    }
    
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
