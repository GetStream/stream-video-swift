//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension CallRejectedEvent {
    static func dummy(
        call: CallResponse = CallResponse.dummy(),
        callCid: String = "",
        createdAt: Date = Date(timeIntervalSince1970: 0),
        type: String = "call.rejected",
        user: UserResponse = UserResponse.dummy()
    ) -> CallRejectedEvent {
        .init(
            call: call,
            callCid: callCid,
            createdAt: createdAt,
            user: user
        )
    }
}
