//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension MemberResponse {
    static func dummy(
        createdAt: Date = .init(timeIntervalSince1970: 0),
        custom: [String: RawJSON] = [:],
        deletedAt: Date? = nil,
        role: String? = nil,
        updatedAt: Date = .init(timeIntervalSince1970: 10),
        user: UserResponse? = nil,
        userId: String = .unique
    ) -> MemberResponse {
        .init(
            createdAt: createdAt,
            custom: custom,
            deletedAt: deletedAt,
            role: role,
            updatedAt: updatedAt,
            user: user ?? .dummy(id: userId),
            userId: userId
        )
    }
}
