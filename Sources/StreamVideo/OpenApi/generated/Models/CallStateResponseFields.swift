//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// CallStateResponseFields is the payload for call state response
public final class CallStateResponseFields: @unchecked Sendable, Decodable {
    /// Represents a call
    public var call: CallResponse
    /// List of call members
    public var members: [MemberResponse]
    /// MemberResponse is the payload for a member of a call.
    public var membership: MemberResponse?
    public var ownCapabilities: [OwnCapability]

    public init(
        call: CallResponse,
        members: [MemberResponse],
        membership: MemberResponse? = nil,
        ownCapabilities: [OwnCapability]
    ) {
        self.call = call
        self.members = members
        self.membership = membership
        self.ownCapabilities = ownCapabilities
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.call = try container.decode(CallResponse.self, forKey: .call)
        self.members = try container.decode([MemberResponse].self, forKey: .members)
        self.membership = try container.decodeIfPresent(MemberResponse.self, forKey: .membership)
        self.ownCapabilities = try container.decode([OwnCapability].self, forKey: .ownCapabilities)
    }
}

extension CallStateResponseFields: Hashable {
    public static func == (lhs: CallStateResponseFields, rhs: CallStateResponseFields) -> Bool {
        lhs.call == rhs.call &&
            lhs.members == rhs.members &&
            lhs.membership == rhs.membership &&
            lhs.ownCapabilities == rhs.ownCapabilities
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(call)
        hasher.combine(members)
        hasher.combine(membership)
        hasher.combine(ownCapabilities)
    }
}
