//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI
import StreamVideo
import StreamVideoSwiftUI

struct DemoVideoCallParticipantModifier: ViewModifier {

    @State var popoverShown = false
    @State var statsShown = false

    var participant: CallParticipant
    var call: Call?
    var availableFrame: CGRect
    var ratio: CGFloat
    var showAllInfo: Bool

    init(
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

    func body(content: Content) -> some View {
        withLongPress {
            content
                .modifier(
                    VideoCallParticipantModifier(
                        participant: participant,
                        call: call,
                        availableFrame: availableFrame,
                        ratio: ratio,
                        showAllInfo: showAllInfo,
                        decorations: [.speaking]
                    )
                )
                .modifier(ReactionsViewModifier(participant: participant))
                .participantStats(call: call, participant: participant)
        }
    }
    
    @MainActor
    private var participantCount: Int {
        call?.state.participants.count ?? 0
    }

    @MainActor 
    @ViewBuilder
    private func withLongPress<Content: View>(
        @ViewBuilder _ content: () -> Content
    ) -> some View {
        if call?.state.sessionId == participant.sessionId, participant.hasVideo {
            content().longPressToFocus(
                availableFrame: availableFrame
            ) { try? call?.focus(at: $0) }
        } else {
            content()
        }
    }
}
