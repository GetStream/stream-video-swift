//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension JoinCallResponse {
    static func dummy(
        call: CallResponse = .dummy(),
        created: Bool = false,
        credentials: Credentials = .dummy(),
        duration: String = "",
        members: [MemberResponse] = [],
        membership: MemberResponse? = nil,
        ownCapabilities: [OwnCapability] = [],
        statsOptions: StatsOptions = .init(reportingIntervalMs: 0)
    ) -> JoinCallResponse {
        .init(
            call: call,
            created: created,
            credentials: credentials,
            duration: duration,
            members: members,
            membership: membership,
            ownCapabilities: ownCapabilities,
            statsOptions: statsOptions
        )
    }
}
