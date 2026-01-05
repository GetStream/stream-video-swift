//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension CallSessionParticipantLeftEvent {
    static func dummy(
        callCid: String = "",
        createdAt: Date = Date(timeIntervalSince1970: 0),
        participant: CallParticipantResponse = CallParticipantResponse.dummy(),
        sessionId: String = "",
        type: String = "call.session_participant_left",
        durationSeconds: Int = 0
    ) -> CallSessionParticipantLeftEvent {
        .init(
            callCid: callCid,
            createdAt: createdAt,
            durationSeconds: durationSeconds,
            participant: participant,
            sessionId: sessionId
        )
    }
}
