//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// Response for updating a call
public final class UpdateCallResponse: @unchecked Sendable, Decodable {
    /// Represents a call
    public var call: CallResponse
    public var duration: String
    public var members: [MemberResponse]
    /// MemberResponse is the payload for a member of a call.
    public var membership: MemberResponse?
    public var ownCapabilities: [OwnCapability]

    public init(
        call: CallResponse,
        duration: String,
        members: [MemberResponse],
        membership: MemberResponse? = nil,
        ownCapabilities: [OwnCapability]
    ) {
        self.call = call
        self.duration = duration
        self.members = members
        self.membership = membership
        self.ownCapabilities = ownCapabilities
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.call = try container.decode(CallResponse.self, forKey: .call)
        self.duration = try container.decode(String.self, forKey: .duration)
        self.members = try container.decode([MemberResponse].self, forKey: .members)
        self.membership = try container.decodeIfPresent(MemberResponse.self, forKey: .membership)
        self.ownCapabilities = try container.decode([OwnCapability].self, forKey: .ownCapabilities)
    }
}

extension UpdateCallResponse: Hashable {
    public static func == (lhs: UpdateCallResponse, rhs: UpdateCallResponse) -> Bool {
        lhs.call == rhs.call &&
            lhs.duration == rhs.duration &&
            lhs.members == rhs.members &&
            lhs.membership == rhs.membership &&
            lhs.ownCapabilities == rhs.ownCapabilities
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(call)
        hasher.combine(duration)
        hasher.combine(members)
        hasher.combine(membership)
        hasher.combine(ownCapabilities)
    }
}
