//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension CallParticipantResponse {
    static func dummy(
        joinedAt: Date = Date(timeIntervalSince1970: 0),
        role: String = "",
        user: UserResponse = UserResponse.dummy(),
        userSessionId: String = ""
    ) -> CallParticipantResponse {
        .init(
            joinedAt: joinedAt,
            role: role,
            user: user,
            userSessionId: userSessionId
        )
    }
}
