//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import SwiftUI

public struct VideoCallParticipantModifier: ViewModifier {

    var call: Call?
    var availableFrame: CGRect
    var ratio: CGFloat
    var showAllInfo: Bool
    var decorations: Set<VideoCallParticipantDecoration>

    @State var participant: CallParticipant
    var participantPublisher: AnyPublisher<CallParticipant, Never>?

    @State var participantsCount: Int
    var participantsCountPublisher: AnyPublisher<Int, Never>?

    public init(
        participant: CallParticipant,
        call: Call?,
        availableFrame: CGRect,
        ratio: CGFloat,
        showAllInfo: Bool,
        decorations: [VideoCallParticipantDecoration] = VideoCallParticipantDecoration.allCases
    ) {
        self.call = call
        self.availableFrame = availableFrame
        self.ratio = ratio
        self.showAllInfo = showAllInfo
        self.decorations = .init(decorations)

        self.participant = participant
        participantPublisher = call?
            .state
            .$participantsMap
            .compactMap { $0[participant.sessionId] }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()

        participantsCount = call?.state.participants.endIndex ?? 0
        participantsCountPublisher = call?
            .state
            .$participants
            .map(\.endIndex)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    public func body(content: Content) -> some View {
        content
            .adjustVideoFrame(to: availableFrame.size.width, ratio: ratio)
            .overlay(participantInfoView)
            .applyDecorationModifierIfRequired(
                VideoCallParticipantOptionsModifier(participant: participant, call: call),
                decoration: .options,
                availableDecorations: decorations
            )
            .applyDecorationModifierIfRequired(
                VideoCallParticipantSpeakingModifier(participant: participant, participantCount: participantsCount),
                decoration: .speaking,
                availableDecorations: decorations
            )
            .onReceive(participantPublisher) { participant = $0 }
            .onReceive(participantsCountPublisher) { participantsCount = $0 }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .clipped()
    }

    @ViewBuilder
    var participantInfoView: some View {
        BottomView {
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
        }
    }
}
