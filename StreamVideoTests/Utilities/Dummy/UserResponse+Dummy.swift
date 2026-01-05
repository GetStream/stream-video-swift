//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension UserResponse {
    static func dummy(
        createdAt: Date = Date(timeIntervalSince1970: 0),
        custom: [String: RawJSON] = [:],
        deletedAt: Date? = nil,
        id: String = .unique,
        image: String? = nil,
        language: String = "",
        name: String? = nil,
        role: String = "",
        teams: [String] = [],
        updatedAt: Date = Date(timeIntervalSince1970: 0)
    ) -> UserResponse {
        .init(
            blockedUserIds: [],
            createdAt: createdAt,
            custom: custom,
            deletedAt: deletedAt,
            id: id,
            image: image,
            language: language,
            name: name,
            role: role,
            teams: teams,
            updatedAt: updatedAt
        )
    }
}
