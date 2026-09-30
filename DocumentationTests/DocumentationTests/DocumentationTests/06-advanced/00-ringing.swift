//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

@MainActor
private func content() {
    asyncContainer {
        let call = streamVideo.call(callType: "default", callId: callId)
        let callResponse = try await call.create(members: members, ring: true)
    }

    asyncContainer {
        let call = streamVideo.call(callType: "default", callId: callId)
        let callResponse = try await call.get(ring: true)
    }

    asyncContainer {
        let call = streamVideo.call(callType: "default", callId: callId)
        let callResponse = try await call.ring()
    }

    // Caller recovery polls automatically when ring events are lost.
    // Use getRingState() for custom UI; it does not update Call.state.
    asyncContainer {
        let call = streamVideo.call(callType: "default", callId: callId)
        let ringState = try await call.getRingState()
        let acceptedUserIds = Array(ringState.acceptedBy.keys)
        let rejectedUserIds = Array(ringState.rejectedBy.keys)
        let missedUserIds = Array(ringState.missedBy.keys)
        let hasEnded = ringState.sessionEndedAt != nil
            || ringState.callEndedAt != nil
    }

    // Save the session ID to read outcomes after the current session clears.
    asyncContainer {
        let call = streamVideo.call(callType: "default", callId: callId)
        let callResponse = try await call.create(members: members, ring: true)
        guard let sessionId = callResponse.session?.id else { return }
        let ringState = try await call.getRingState(callSessionId: sessionId)
    }

    asyncContainer {
        let call = streamVideo.call(callType: "default", callId: callId)
        let callResponse = try await call.create(members: members, notify: true)
    }

    asyncContainer {
        let call = streamVideo.call(callType: "default", callId: callId)
        let callResponse = try await call.get(notify: true)
    }

    asyncContainer {
        let call = streamVideo.call(callType: "default", callId: callId)
        let callResponse = try await call.notify()
    }

    container {
        let callViewModel = CallViewModel()
        callViewModel.participantAutoLeavePolicy = LastParticipantAutoLeavePolicy()
    }
}
