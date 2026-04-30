//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoVideoCallParticipantModifier: ViewModifier {

    @State var popoverShown = false
    @State var statsShown = false

    var participant: CallParticipant
    var call: Call?
    var availableFrame: CGRect
    var ratio: CGFloat
    var showAllInfo: Bool
    private var enabledDecorations: Set<DemoCallParticipantDecoration>

    init(
        participant: CallParticipant,
        call: Call?,
        availableFrame: CGRect,
        ratio: CGFloat,
        showAllInfo: Bool,
        decorations: [DemoCallParticipantDecoration] = [.sdkSpeakingRing, .demoExtendedMenu]
    ) {
        self.participant = participant
        self.call = call
        self.availableFrame = availableFrame
        self.ratio = ratio
        self.showAllInfo = showAllInfo
        self.enabledDecorations = DemoCallParticipantDecoration.normalizedSet(decorations)
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
                        decorations: Array(enabledDecorations.asVideoCallParticipantDecorations())
                    )
                )
                .applyDemoDecorationModifierIfRequired(
                    DemoExtendedParticipantOptionsOverlayModifier(
                        participant: participant,
                        call: call
                    ),
                    decoration: .demoExtendedMenu,
                    availableDecorations: enabledDecorations
                )
                .modifier(ReactionsViewModifier(participant: participant))
        }
    }

    @MainActor
    @ViewBuilder
    private func withLongPress<Content: View>(
        @ViewBuilder _ content: () -> Content
    ) -> some View {
        if call?.state.sessionId == participant.sessionId, participant.hasVideo {
            content().longPressToFocus(
                availableFrame: availableFrame
            ) { [weak call] point in
                Task { [weak call] in
                    do {
                        try await call?.focus(at: point)
                    } catch {
                        log.error(error)
                    }
                }
            }
        } else {
            content()
        }
    }
}
