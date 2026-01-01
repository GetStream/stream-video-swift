//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension CallSessionResponse {
    static func dummy(
        acceptedBy: [String: Date] = [:],
        endedAt: Date? = nil,
        id: String = "",
        liveEndedAt: Date? = nil,
        liveStartedAt: Date? = nil,
        participants: [CallParticipantResponse] = [],
        participantsCountByRole: [String: Int] = [:],
        rejectedBy: [String: Date] = [:],
        startedAt: Date? = nil
    ) -> CallSessionResponse {
        .init(
            acceptedBy: acceptedBy,
            anonymousParticipantCount: 0,
            endedAt: endedAt,
            id: id,
            liveEndedAt: liveEndedAt,
            liveStartedAt: liveStartedAt,
            missedBy: [:],
            participants: participants,
            participantsCountByRole: participantsCountByRole,
            rejectedBy: rejectedBy,
            startedAt: startedAt
        )
    }
}
