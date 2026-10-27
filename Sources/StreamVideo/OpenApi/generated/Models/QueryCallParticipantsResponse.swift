//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class QueryCallParticipantsResponse: @unchecked Sendable, Codable, JSONEncodable {
    /// Represents a call
    public var call: CallResponse
    public var duration: String
    public var members: [MemberResponse]
    /// MemberResponse is the payload for a member of a call.
    public var membership: MemberResponse?
    public var ownCapabilities: [OwnCapability]
    /// List of call participants
    public var participants: [CallParticipantResponse]
    public var totalParticipants: Int

    public init(
        call: CallResponse,
        duration: String,
        members: [MemberResponse],
        membership: MemberResponse? = nil,
        ownCapabilities: [OwnCapability],
        participants: [CallParticipantResponse],
        totalParticipants: Int
    ) {
        self.call = call
        self.duration = duration
        self.members = members
        self.membership = membership
        self.ownCapabilities = ownCapabilities
        self.participants = participants
        self.totalParticipants = totalParticipants
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.call = try container.decode(CallResponse.self, forKey: .call)
        self.duration = try container.decode(String.self, forKey: .duration)
        self.members = try container.decode([MemberResponse].self, forKey: .members)
        self.membership = try container.decodeIfPresent(MemberResponse.self, forKey: .membership)
        self.ownCapabilities = try container.decode([OwnCapability].self, forKey: .ownCapabilities)
        self.participants = try container.decode([CallParticipantResponse].self, forKey: .participants)
        self.totalParticipants = try container.decode(Int.self, forKey: .totalParticipants)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(call, forKey: .call)
        try container.encode(duration, forKey: .duration)
        try container.encode(members, forKey: .members)
        try container.encodeIfPresent(membership, forKey: .membership)
        try container.encode(ownCapabilities, forKey: .ownCapabilities)
        try container.encode(participants, forKey: .participants)
        try container.encode(totalParticipants, forKey: .totalParticipants)
    }
}

extension QueryCallParticipantsResponse: Hashable {
    public static func == (lhs: QueryCallParticipantsResponse, rhs: QueryCallParticipantsResponse) -> Bool {
        lhs.call == rhs.call &&
            lhs.duration == rhs.duration &&
            lhs.members == rhs.members &&
            lhs.membership == rhs.membership &&
            lhs.ownCapabilities == rhs.ownCapabilities &&
            lhs.participants == rhs.participants &&
            lhs.totalParticipants == rhs.totalParticipants
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(call)
        hasher.combine(duration)
        hasher.combine(members)
        hasher.combine(membership)
        hasher.combine(ownCapabilities)
        hasher.combine(participants)
        hasher.combine(totalParticipants)
    }
}
