//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class CallStateResponseFields: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var call: CallResponse
    public var members: [MemberResponse]
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
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case call
        case members
        case membership
        case ownCapabilities = "own_capabilities"
    }
    
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
