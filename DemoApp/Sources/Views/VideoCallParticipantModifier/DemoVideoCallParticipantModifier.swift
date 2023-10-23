//
// Copyright © 2023 Stream.io Inc. All rights reserved.
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
        content
            .modifier(
                VideoCallParticipantModifier(
                    participant: participant,
                    call: call,
                    availableFrame: availableFrame,
                    ratio: ratio,
                    showAllInfo: showAllInfo)
            )
            .modifier(
                ReactionsViewModifier(
                    participant: participant,
                    availableSize: availableFrame.size
                )
            )
            .longPressToFocus(availableFrame: availableFrame) {
                guard call?.state.sessionId == participant.sessionId else { return }
                try? call?.tapToFocus(at: $0)
            }
    }
    
    @MainActor
    private var participantCount: Int {
        call?.state.participants.count ?? 0
    }
}
