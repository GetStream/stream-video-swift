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
        try await call.pin(sessionId: "pinned_user_session_id")
    }

    asyncContainer {
        try await call.unpin(sessionId: "pinned_user_session_id")
    }

    asyncContainer {
        let response = try await call.pinForEveryone(userId: "pinned_user_id", sessionId: "pinned_user_session_id")
    }

    asyncContainer {
        let response = try await call.unpinForEveryone(userId: "pinned_user_id", sessionId: "pinned_user_session_id")
    }

    container {
        struct CustomVideoCallParticipantModifier: ViewModifier {

            var participant: CallParticipant
            var call: Call?
            var availableFrame: CGRect
            var ratio: CGFloat
            var showAllInfo: Bool

            public init(
                participant: CallParticipant,
                call: Call?,
                availableFrame: CGRect,
                ratio: CGFloat,
                showAllInfo: Bool
            ) {
                self.participant = participant
                self.call = call
                self.availableFrame = availableFrame
                self.ratio = ratio
                self.showAllInfo = showAllInfo
            }

            public func body(content: Content) -> some View {
                content
            }
        }

        func makeVideoCallParticipantModifier(
            participant: CallParticipant,
            call: Call?,
            availableFrame: CGRect,
            ratio: CGFloat,
            showAllInfo: Bool
        ) -> some ViewModifier {
            CustomVideoCallParticipantModifier(
                participant: participant,
                call: call,
                availableFrame: availableFrame,
                ratio: ratio,
                showAllInfo: showAllInfo
            )
        }
    }
}
