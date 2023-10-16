//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI
import WebRTC

public struct ParticipantsSpotlightLayout<Factory: ViewFactory>: View {
    
    private let thumbnailSize: CGFloat = 120
    
    var viewFactory: Factory
    var participant: CallParticipant
    var participants: [CallParticipant]
    var frame: CGRect
    var call: Call?
    var onChangeTrackVisibility: @MainActor(CallParticipant, Bool) -> Void
    
    public init(
        viewFactory: Factory,
        participant: CallParticipant,
        call: Call?,
        participants: [CallParticipant],
        frame: CGRect,
        onChangeTrackVisibility: @escaping @MainActor (CallParticipant, Bool) -> Void
    ) {
        self.viewFactory = viewFactory
        self.participant = participant
        self.participants = participants
        self.frame = frame
        self.call = call
        self.onChangeTrackVisibility = onChangeTrackVisibility
    }

    public var body: some View {
        VStack {
            viewFactory.makeVideoParticipantView(
                participant: participant,
                id: "\(participant.id)-spotlight",
                availableFrame: topParticipantFrame,
                contentMode: .scaleAspectFill,
                customData: [:],
                call: call
            )
            .modifier(
                viewFactory.makeVideoCallParticipantModifier(
                    participant: participant,
                    call: call,
                    availableFrame: topParticipantFrame,
                    ratio: topParticipantRatio,
                    showAllInfo: true
                )
            )
            .modifier(ParticipantChangeModifier(
                participant: participant,
                onChangeTrackVisibility: onChangeTrackVisibility)
            )
            .visibilityObservation(in: topParticipantFrame) {
                onChangeTrackVisibility(participant, $0)
            }

            ScrollView(.horizontal) {
                HorizontalContainer {
                    ForEach(participants) { participant in
                        viewFactory.makeVideoParticipantView(
                            participant: participant,
                            id: participant.id,
                            availableFrame: participantStripItemFrame,
                            contentMode: .scaleAspectFill,
                            customData: [:],
                            call: call
                        )
                        .modifier(
                            viewFactory.makeVideoCallParticipantModifier(
                                participant: participant,
                                call: call,
                                availableFrame: participantStripItemFrame,
                                ratio: participantsStripItemRatio,
                                showAllInfo: true
                            )
                        )
                        .visibilityObservation(in: participantsStripFrame) { onChangeTrackVisibility(participant, $0) }
                        .cornerRadius(8)
                        .accessibility(identifier: "spotlightParticipantView")
                    }
                }
                .frame(height: participantStripItemFrame.height)
                .cornerRadius(8)
            }
            .padding()
            .padding(.bottom)
            .accessibility(identifier: "spotlightScrollView")
        }
    }
    
    private var topParticipantFrame: CGRect {
        .init(
            origin: frame.origin,
            size: CGSize(width: frame.size.width, height: frame.size.height - thumbnailSize - 64)
        )
    }

    private var participantsStripFrame: CGRect {
        .init(
            origin: .init(x: frame.origin.x, y: frame.maxY - thumbnailSize),
            size: CGSize(width: frame.size.width, height: thumbnailSize)
        )
    }

    private var topParticipantRatio: CGFloat {
        topParticipantFrame.size.width / topParticipantFrame.size.height
    }
    
    private var participantsStripItemRatio: CGFloat {
        participantsStripFrame.size.width / participantsStripFrame.size.height
    }

    private var participantStripItemFrame: CGRect {
        .init(origin: .zero, size: .init(width: participantsStripFrame.height, height: participantsStripFrame.height))
    }
}
