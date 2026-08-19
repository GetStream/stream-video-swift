//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension CallReaction {
    static func dummy(
        id: String = .unique,
        type: String = ":like:",
        emojiCode: String? = nil,
        custom: [String: RawJSON] = [:],
        user: User = .dummy(),
        createdAt: Date = .init(timeIntervalSince1970: 0)
    ) -> CallReaction {
        .init(
            id: id,
            type: type,
            emojiCode: emojiCode,
            custom: custom,
            user: user,
            createdAt: createdAt
        )
    }
}
