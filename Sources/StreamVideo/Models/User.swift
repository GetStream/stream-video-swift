//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public extension UserResponse {
    static func make(from id: String) -> UserResponse {
        UserResponse(
            blockedUserIds: [],
            createdAt: Date(),
            custom: [:],
            id: id,
            language: Locale.current.languageCode ?? "en",
            role: "user",
            teams: [],
            updatedAt: Date()
        )
    }
}
