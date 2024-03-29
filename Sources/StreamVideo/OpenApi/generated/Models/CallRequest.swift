//
// CallRequest.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation


public struct CallRequest: Codable, JSONEncodable, Hashable {
    public var custom: [String: RawJSON]?
    public var members: [MemberRequest]?
    public var settingsOverride: CallSettingsRequest?
    public var startsAt: Date?
    public var team: String?

    public init(custom: [String: RawJSON]? = nil, members: [MemberRequest]? = nil, settingsOverride: CallSettingsRequest? = nil, startsAt: Date? = nil, team: String? = nil) {
        self.custom = custom
        self.members = members
        self.settingsOverride = settingsOverride
        self.startsAt = startsAt
        self.team = team
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case custom
        case members
        case settingsOverride = "settings_override"
        case startsAt = "starts_at"
        case team
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(custom, forKey: .custom)
        try container.encodeIfPresent(members, forKey: .members)
        try container.encodeIfPresent(settingsOverride, forKey: .settingsOverride)
        try container.encodeIfPresent(startsAt, forKey: .startsAt)
        try container.encodeIfPresent(team, forKey: .team)
    }
}

