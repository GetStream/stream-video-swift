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
    var call: Call?
    var onChangeTrackVisibility: @MainActor(CallParticipant, Bool) -> Void
    
    public init(
        viewFactory: Factory,
        participant: CallParticipant,
        call: Call?,
        participants: [CallParticipant],
        size: CGSize,
        onChangeTrackVisibility: @escaping @MainActor (CallParticipant, Bool) -> Void
    ) {
        self.viewFactory = viewFactory
        self.participant = participant
        self.participants = participants
        self.size = size
        self.call = call
        self.onChangeTrackVisibility = onChangeTrackVisibility
    }

    
    public var body: some View {
        VStack {
            viewFactory.makeVideoParticipantView(
                participant: participant,
                id: "\(participant.id)-spotlight",
                availableSize: .init(width: thumbnailSize, height: thumbnailSize),
                contentMode: .scaleAspectFill,
                customData: [:],
                call: call
            )
            .modifier(
                viewFactory.makeVideoCallParticipantModifier(
                    participant: participant,
                    call: call,
                    availableSize: availableSize,
                    ratio: ratio,
                    showAllInfo: true
                )
            )
            .modifier(ParticipantChangeModifier(
                participant: participant,
                onChangeTrackVisibility: onChangeTrackVisibility)
            )
            
            ScrollView(.horizontal) {
                GeometryReader { geometry in
                    HorizontalContainer {
                        ForEach(participants) { participant in
                            viewFactory.makeVideoParticipantView(
                                participant: participant,
                                id: participant.id,
                                availableSize: .init(width: thumbnailSize, height: thumbnailSize),
                                contentMode: .scaleAspectFill,
                                customData: [:],
                                call: call
                            )
                            .visibilityObservation(in: geometry.frame(in: .global)) { onChangeTrackVisibility(participant, $0) }
                            .adjustVideoFrame(to: thumbnailSize, ratio: 1)
                            .cornerRadius(8)
                            .accessibility(identifier: "spotlightParticipantView")
                        }
                    }
                    .frame(height: thumbnailSize)
                    .cornerRadius(8)
                }
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
