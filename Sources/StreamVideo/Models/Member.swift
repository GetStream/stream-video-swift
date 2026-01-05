//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Represents a member in the call.
public struct Member: Identifiable, Equatable, Sendable, Codable {
    /// The member's id.
    public var id: String {
        user.id
    }

    /// The underlying user.
    public let user: User
    /// The role of the member in the call.
    public let role: String
    /// Custom data of the member in the call.
    public let customData: [String: RawJSON]
    public let updatedAt: Date?

    public init(user: User, role: String? = nil, customData: [String: RawJSON] = [:], updatedAt: Date? = nil) {
        self.user = user
        self.role = role ?? user.role
        self.customData = customData
        self.updatedAt = updatedAt
    }
    
    public init(userId: String, role: String? = nil, customData: [String: RawJSON] = [:], updatedAt: Date? = nil) {
        user = User(id: userId)
        self.role = role ?? user.role
        self.customData = customData
        self.updatedAt = updatedAt
    }
}

public extension MemberResponse {
    var toMember: Member {
        Member(
            user: user.toUser,
            role: role ?? "",
            customData: custom,
            updatedAt: updatedAt
        )
    }
}

public extension Member {
    var toMemberRequest: MemberRequest {
        MemberRequest(
            custom: customData,
            role: role,
            userId: user.id
        )
    }
}

public extension MemberRequest {
    var toMember: Member {
        Member(
            user: User(id: userId),
            role: role,
            customData: custom ?? [:],
            updatedAt: Date()
        )
    }
}
