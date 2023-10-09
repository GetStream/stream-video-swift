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
                availableFrame: .init(origin: .zero, size: .init(width: thumbnailSize, height: thumbnailSize)),
                contentMode: .scaleAspectFill,
                customData: [:],
                call: call
            )
            .modifier(
                viewFactory.makeVideoCallParticipantModifier(
                    participant: participant,
                    call: call,
                    availableFrame: availableFrame,
                    ratio: ratio,
                    showAllInfo: true
                )
            )
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
                            availableFrame: .init(origin: .zero, size: .init(width: thumbnailSize, height: thumbnailSize)),
                            contentMode: .scaleAspectFill,
                            customData: [:],
                            call: call
                        )
                        .visibilityObservation(in: availableFrame) { onChangeTrackVisibility(participant, $0) }
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
    
    private var availableFrame: CGRect {
        .init(
            origin: frame.origin,
            size: CGSize(width: frame.size.width, height: frame.size.height - thumbnailSize - 64)
        )
    }
    
    private var ratio: CGFloat {
        availableFrame.size.width / availableFrame.size.height
    }
}
