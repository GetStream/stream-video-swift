//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo

extension GetCallRingStateResponse {
    static func dummy(
        acceptedBy: [String: Date] = [:],
        callEndedAt: Date? = nil,
        missedBy: [String: Date] = [:],
        rejectedBy: [String: Date] = [:],
        sessionEndedAt: Date? = nil,
        sessionId: String = ""
    ) -> GetCallRingStateResponse {
        .init(
            acceptedBy: acceptedBy,
            callCid: "default:\(String.unique)",
            callEndedAt: callEndedAt,
            createdByUserId: "",
            duration: "",
            missedBy: missedBy,
            rejectedBy: rejectedBy,
            sessionEndedAt: sessionEndedAt,
            sessionId: sessionId
        )
    }
}
