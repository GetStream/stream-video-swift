//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class JoinCallResponse: Sendable, Decodable {
    /// Represents a call
    public let call: CallResponse
    public let created: Bool
    public let credentials: Credentials
    public let duration: String
    public let members: [MemberResponse]
    /// MemberResponse is the payload for a member of a call.
    public let membership: MemberResponse?
    public let ownCapabilities: [OwnCapability]
    /// How the client should play the call when it is not given SFU credentials
    public let playback: PlaybackResponse?
    public let statsOptions: StatsOptions

    public init(
        call: CallResponse,
        created: Bool,
        credentials: Credentials,
        duration: String,
        members: [MemberResponse],
        membership: MemberResponse? = nil,
        ownCapabilities: [OwnCapability],
        playback: PlaybackResponse? = nil,
        statsOptions: StatsOptions
    ) {
        self.call = call
        self.created = created
        self.credentials = credentials
        self.duration = duration
        self.members = members
        self.membership = membership
        self.ownCapabilities = ownCapabilities
        self.playback = playback
        self.statsOptions = statsOptions
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.call = try container.decode(CallResponse.self, forKey: .call)
        self.created = try container.decode(Bool.self, forKey: .created)
        self.credentials = try container.decode(Credentials.self, forKey: .credentials)
        self.duration = try container.decode(String.self, forKey: .duration)
        self.members = try container.decode([MemberResponse].self, forKey: .members)
        self.membership = try container.decodeIfPresent(MemberResponse.self, forKey: .membership)
        self.ownCapabilities = try container.decode([OwnCapability].self, forKey: .ownCapabilities)
        self.playback = try container.decodeIfPresent(PlaybackResponse.self, forKey: .playback)
        self.statsOptions = try container.decode(StatsOptions.self, forKey: .statsOptions)
    }
}

extension JoinCallResponse: Hashable {
    public static func == (lhs: JoinCallResponse, rhs: JoinCallResponse) -> Bool {
        lhs.call == rhs.call &&
            lhs.created == rhs.created &&
            lhs.credentials == rhs.credentials &&
            lhs.duration == rhs.duration &&
            lhs.members == rhs.members &&
            lhs.membership == rhs.membership &&
            lhs.ownCapabilities == rhs.ownCapabilities &&
            lhs.playback == rhs.playback &&
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
        hasher.combine(playback)
        hasher.combine(statsOptions)
    }
}
