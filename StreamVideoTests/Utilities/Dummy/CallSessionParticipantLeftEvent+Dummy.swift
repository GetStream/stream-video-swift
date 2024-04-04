//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension CallSessionParticipantLeftEvent {
    static func dummy(
        callCid: String = "",
        createdAt: Date = Date(timeIntervalSince1970: 0),
        participant: CallParticipantResponse = CallParticipantResponse.dummy(),
        sessionId: String = "",
        type: String = "call.session_participant_left"
    ) -> CallSessionParticipantLeftEvent {
        .init(
            callCid: callCid,
            createdAt: createdAt,
            participant: participant,
            sessionId: sessionId,
            type: type
        )
    }
}
