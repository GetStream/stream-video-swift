//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class GetOrCreateCallResponse: @unchecked Sendable, Decodable {
    /// Represents a call
    public var call: CallResponse
    public var created: Bool
    public var duration: String
    public var members: [MemberResponse]
    /// MemberResponse is the payload for a member of a call.
    public var membership: MemberResponse?
    public var ownCapabilities: [OwnCapability]

    public init(
        call: CallResponse,
        created: Bool,
        duration: String,
        members: [MemberResponse],
        membership: MemberResponse? = nil,
        ownCapabilities: [OwnCapability]
    ) {
        self.call = call
        self.created = created
        self.duration = duration
        self.members = members
        self.membership = membership
        self.ownCapabilities = ownCapabilities
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.call = try container.decode(CallResponse.self, forKey: .call)
        self.created = try container.decode(Bool.self, forKey: .created)
        self.duration = try container.decode(String.self, forKey: .duration)
        self.members = try container.decode([MemberResponse].self, forKey: .members)
        self.membership = try container.decodeIfPresent(MemberResponse.self, forKey: .membership)
        self.ownCapabilities = try container.decode([OwnCapability].self, forKey: .ownCapabilities)
    }
}

extension GetOrCreateCallResponse: Hashable {
    public static func == (lhs: GetOrCreateCallResponse, rhs: GetOrCreateCallResponse) -> Bool {
        lhs.call == rhs.call &&
            lhs.created == rhs.created &&
            lhs.duration == rhs.duration &&
            lhs.members == rhs.members &&
            lhs.membership == rhs.membership &&
            lhs.ownCapabilities == rhs.ownCapabilities
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(call)
        hasher.combine(created)
        hasher.combine(duration)
        hasher.combine(members)
        hasher.combine(membership)
        hasher.combine(ownCapabilities)
    }
}
