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
    var size: CGSize
    @Binding var pinnedParticipant: CallParticipant?
    var onViewRendering: (VideoRenderer, CallParticipant) -> Void
    var onChangeTrackVisibility: @MainActor(CallParticipant, Bool) -> Void
    
    public init(
        viewFactory: Factory,
        participant: CallParticipant,
        participants: [CallParticipant],
        size: CGSize,
        pinnedParticipant: Binding<CallParticipant?>,
        onViewRendering: @escaping (VideoRenderer, CallParticipant) -> Void,
        onChangeTrackVisibility: @escaping @MainActor (CallParticipant, Bool) -> Void
    ) {
        self.viewFactory = viewFactory
        self.participant = participant
        self.participants = participants
        self.size = size
        _pinnedParticipant = pinnedParticipant
        self.onViewRendering = onViewRendering
        self.onChangeTrackVisibility = onChangeTrackVisibility
    }

    
    public var body: some View {
        VStack {
            viewFactory.makeVideoParticipantView(
                participant: participant,
                id: "\(participant.id)-spotlight",
                availableSize: .init(width: thumbnailSize, height: thumbnailSize),
                contentMode: .scaleAspectFill,
                customData: [:]
            ) { participant, view in
                onViewRendering(view, participant)
            }
            .modifier(
                viewFactory.makeVideoCallParticipantModifier(
                    participant: participant,
                    participantCount: 1,
                    pinnedParticipant: $pinnedParticipant,
                    availableSize: availableSize,
                    ratio: ratio
                )
            )
            .onAppear {
                log.debug("Participant \(participant.name) is visible")
                onChangeTrackVisibility(participant, true)
            }
            .modifier(ParticipantChangeModifier(
                participant: participant,
                onChangeTrackVisibility: onChangeTrackVisibility)
            )
            
            ScrollView(.horizontal) {
                HorizontalContainer {
                    ForEach(participants) { participant in
                        viewFactory.makeVideoParticipantView(
                            participant: participant,
                            id: participant.id,
                            availableSize: .init(width: thumbnailSize, height: thumbnailSize),
                            contentMode: .scaleAspectFill,
                            customData: [:]
                        ) { participant, view in
                            onViewRendering(view, participant)
                        }
                        .onAppear {
                            onChangeTrackVisibility(participant, true)
                        }
                        .onDisappear {
                            onChangeTrackVisibility(participant, false)
                        }
                        .adjustVideoFrame(to: thumbnailSize, ratio: 1)
                        .cornerRadius(8)
                        .accessibility(identifier: "spotlightParticipantView")
                    }
                }
                .frame(height: thumbnailSize)
                .cornerRadius(8)
            }
            .padding()
            .padding(.bottom)
            .accessibility(identifier: "spotlightScrollView")
        }

    }
    
    private var availableSize: CGSize {
        CGSize(width: size.width, height: size.height - thumbnailSize - 64)
    }
    
    private var ratio: CGFloat {
        availableSize.width / availableSize.height
    }
}
