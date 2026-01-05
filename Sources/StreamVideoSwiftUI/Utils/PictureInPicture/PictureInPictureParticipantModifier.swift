//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

/// Modifies a view to display participant information in Picture-in-Picture.
///
/// Adds participant details, connection quality, and speaking indicators to the view.
private struct PictureInPictureParticipantModifier: ViewModifier {

    var participant: CallParticipant
    var call: Call?
    var showAllInfo: Bool
    var decorations: Set<VideoCallParticipantDecoration>

    /// Creates a new participant modifier.
    ///
    /// - Parameters:
    ///   - participant: The participant to display
    ///   - call: The current call instance
    ///   - showAllInfo: Whether to show additional participant information
    ///   - decorations: The decorations to apply to the participant view
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
                            isPinned: participant.isPinned,
                            paddingsConfig: .participantInfoViewPiP
                        )

                        Spacer()

                        if showAllInfo {
                            ConnectionQualityIndicator(
                                connectionQuality: participant.connectionQuality,
                                paddingsConfig: .connectionIndicator
                            )
                        }
                    }
                })
            )
            .applyDecorationModifierIfRequired(
                VideoCallParticipantSpeakingModifier(
                    participant: participant,
                    participantCount: participantCount,
                    cornerRadius: cornerRadius
                ),
                decoration: .speaking,
                availableDecorations: decorations
            )
    }

    @MainActor
    private var participantCount: Int {
        call?.state.participants.count ?? 0
    }
    
    private var cornerRadius: CGFloat {
        if #available(iOS 26.0, *) {
            return 32
        } else {
            return 16
        }
    }
}

extension View {

    /// Applies participant-specific modifications to a view.
    ///
    /// - Parameters:
    ///   - participant: The participant to display
    ///   - call: The current call instance
    ///   - showAllInfo: Whether to show additional participant information
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
