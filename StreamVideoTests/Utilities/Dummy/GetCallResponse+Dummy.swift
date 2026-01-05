//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension GetCallResponse {
    static func dummy(
        call: CallResponse = .dummy(),
        duration: String = "0",
        members: [MemberResponse] = [],
        membership: MemberResponse? = nil,
        ownCapabilities: [OwnCapability] = []
    ) -> GetCallResponse {
        .init(
            call: call,
            duration: duration,
            members: members,
            membership: membership,
            ownCapabilities: ownCapabilities
        )
    }
}
