//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct VideoCallParticipantModifier: ViewModifier {

    var participant: CallParticipant
    var call: Call?
    var availableFrame: CGRect
    var ratio: CGFloat
    var showAllInfo: Bool
    var decorations: Set<VideoCallParticipantDecoration>

    public init(
        participant: CallParticipant,
        call: Call?,
        availableFrame: CGRect,
        ratio: CGFloat,
        showAllInfo: Bool,
        decorations: [VideoCallParticipantDecoration] = VideoCallParticipantDecoration.allCases
    ) {
        self.participant = participant
        self.call = call
        self.availableFrame = availableFrame
        self.ratio = ratio
        self.showAllInfo = showAllInfo
        self.decorations = .init(decorations)
    }
    
    public func body(content: Content) -> some View {
        content
            .adjustVideoFrame(to: availableFrame.size.width, ratio: ratio)
            .overlay(
                ZStack {
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
                }
            )
            .applyDecorationModifierIfRequired(
                VideoCallParticipantOptionsModifier(participant: participant, call: call),
                decoration: .options,
                availableDecorations: decorations
            )
            .applyDecorationModifierIfRequired(
                VideoCallParticipantSpeakingModifier(participant: participant, participantCount: participantCount),
                decoration: .speaking,
                availableDecorations: decorations
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .clipped()
    }

    @MainActor
    private var participantCount: Int {
        call?.state.participants.count ?? 0
    }
}
