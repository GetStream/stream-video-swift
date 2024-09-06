//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct CallRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
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
}
