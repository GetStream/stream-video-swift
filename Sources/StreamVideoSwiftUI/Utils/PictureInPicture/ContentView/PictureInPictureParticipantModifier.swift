//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

private struct PictureInPictureParticipantModifier: ViewModifier {

    var participant: CallParticipant
    var call: Call?
    var showAllInfo: Bool
    var decorations: Set<VideoCallParticipantDecoration>

    init(
        participant: CallParticipant,
        call: Call?,
        showAllInfo: Bool,
        decorations: [VideoCallParticipantDecoration]
    ) {
        self.participant = participant
        self.call = call
        self.showAllInfo = showAllInfo
        self.decorations = .init(decorations)
    }

    func body(content: Content) -> some View {
        content
            .overlay(
                BottomView(content: {
                    HStack {
                        ParticipantInfoView(
                            participant: participant,
                            isPinned: participant.isPinned
                        )

                        Spacer()

                        if showAllInfo {
                            ConnectionQualityIndicator(
                                connectionQuality: participant.connectionQuality
                            )
                        }
                    }
                })
            )
            .applyDecorationModifierIfRequired(
                VideoCallParticipantSpeakingModifier(participant: participant, participantCount: participantCount),
                decoration: .speaking,
                availableDecorations: decorations
            )
    }

    private var participantCount: Int {
        call?.state.participants.count ?? 0
    }
}

extension View {

    @ViewBuilder
    func pictureInPictureParticipant(
        participant: CallParticipant,
        call: Call?,
        showAllInfo: Bool = true
    ) -> some View {
        modifier(
            PictureInPictureParticipantModifier(
                participant: participant,
                call: call,
                showAllInfo: showAllInfo,
                decorations: [VideoCallParticipantDecoration.speaking]
            )
        )
    }
}
