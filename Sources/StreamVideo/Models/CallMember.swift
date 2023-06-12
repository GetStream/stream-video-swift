//
//  CallMember.swift
//  StreamVideo
//
//  Created by tommaso barbugli on 09/06/2023.
//

import Foundation

extension MemberResponse {
    var toMember: CallMember {
        CallMember(
            user: user.toUser,
            role: role ?? "",
            customData: convert(custom),
            updatedAt: updatedAt
        )
    }
}

public struct CallMember: Identifiable, Equatable, Sendable, Codable {
    public var id: String { user.id }
    public let user: User
    public let role: String
    public let customData: [String: RawJSON]
    public let updatedAt: Date
}
