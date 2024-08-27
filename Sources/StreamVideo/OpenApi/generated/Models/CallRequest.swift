//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct CallRequest: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var custom: [String: RawJSON]? = nil
    public var members: [MemberRequest]? = nil
    public var settingsOverride: CallSettingsRequest? = nil
    public var startsAt: Date? = nil
    public var team: String? = nil
    public var video: Bool? = nil

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
