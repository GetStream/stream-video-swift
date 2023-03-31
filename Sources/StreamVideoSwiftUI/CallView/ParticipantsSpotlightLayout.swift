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
            VideoCallParticipantView(
                participant: participant,
                id: "\(participant.id)-spotlight",
                availableSize: .init(width: thumbnailSize, height: thumbnailSize),
                contentMode: .scaleAspectFill
            ) { participant, view in
                if let track = participant.track {
                    view.add(track: track)
                }
            }
            .onAppear {
                onChangeTrackVisibility(participant, true)
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
            
            ScrollView(.horizontal) {
                HorizontalContainer {
                    ForEach(participants) { participant in
                        VideoCallParticipantView(
                            participant: participant,
                            availableSize: .init(width: thumbnailSize, height: thumbnailSize),
                            contentMode: .scaleAspectFill
                        ) { participant, view in
                            if let track = participant.track {
                                view.add(track: track)
                            }
                        }
                        .onAppear {
                            onChangeTrackVisibility(participant, true)
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
        }

    }
    
    private var availableSize: CGSize {
        CGSize(width: size.width, height: size.height - thumbnailSize - 64)
    }
    
    private var ratio: CGFloat {
        availableSize.width / availableSize.height
    }
}
