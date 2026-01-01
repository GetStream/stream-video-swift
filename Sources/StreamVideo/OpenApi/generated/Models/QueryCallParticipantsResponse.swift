//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class QueryCallParticipantsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    public var call: CallResponse
    public var duration: String
    public var members: [MemberResponse]
    public var membership: MemberResponse?
    public var ownCapabilities: [OwnCapability]
    public var participants: [CallParticipantResponse]
    public var totalParticipants: Int

    public init(call: CallResponse, duration: String, members: [MemberResponse], membership: MemberResponse? = nil, ownCapabilities: [OwnCapability], participants: [CallParticipantResponse], totalParticipants: Int) {
        self.call = call
        self.duration = duration
        self.members = members
        self.membership = membership
        self.ownCapabilities = ownCapabilities
        self.participants = participants
        self.totalParticipants = totalParticipants
    }

public enum CodingKeys: String, CodingKey, CaseIterable {
    case call
    case duration
    case members
    case membership
    case ownCapabilities = "own_capabilities"
    case participants
    case totalParticipants = "total_participants"
}

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
