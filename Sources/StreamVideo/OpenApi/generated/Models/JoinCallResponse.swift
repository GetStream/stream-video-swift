//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class JoinCallResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var call: CallResponse
    public var created: Bool
    public var credentials: Credentials
    public var duration: String
    public var members: [MemberResponse]
    public var membership: MemberResponse?
    public var ownCapabilities: [OwnCapability]
    public var statsOptions: StatsOptions

    public init(
        call: CallResponse,
        created: Bool,
        credentials: Credentials,
        duration: String,
        members: [MemberResponse],
        membership: MemberResponse? = nil,
        ownCapabilities: [OwnCapability],
        statsOptions: StatsOptions
    ) {
        self.call = call
        self.created = created
        self.credentials = credentials
        self.duration = duration
        self.members = members
        self.membership = membership
        self.ownCapabilities = ownCapabilities
        self.statsOptions = statsOptions
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case call
        case created
        case credentials
        case duration
        case members
        case membership
        case ownCapabilities = "own_capabilities"
        case statsOptions = "stats_options"
    }
    
    public static func == (lhs: JoinCallResponse, rhs: JoinCallResponse) -> Bool {
        lhs.call == rhs.call &&
            lhs.created == rhs.created &&
            lhs.credentials == rhs.credentials &&
            lhs.duration == rhs.duration &&
            lhs.members == rhs.members &&
            lhs.membership == rhs.membership &&
            lhs.ownCapabilities == rhs.ownCapabilities &&
            lhs.statsOptions == rhs.statsOptions
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(call)
        hasher.combine(created)
        hasher.combine(credentials)
        hasher.combine(duration)
        hasher.combine(members)
        hasher.combine(membership)
        hasher.combine(ownCapabilities)
        hasher.combine(statsOptions)
    }
}
