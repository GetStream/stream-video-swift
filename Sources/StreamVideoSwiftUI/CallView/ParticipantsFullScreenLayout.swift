//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI
import WebRTC

public struct ParticipantsFullScreenLayout<Factory: ViewFactory>: View {
    
    var viewFactory: Factory
    var participant: CallParticipant
    var size: CGSize
    @Binding var pinnedParticipant: CallParticipant?
    var onViewRendering: (VideoRenderer, CallParticipant) -> Void
    var onChangeTrackVisibility: @MainActor(CallParticipant, Bool) -> Void
    
    public init(
        viewFactory: Factory,
        participant: CallParticipant,
        size: CGSize,
        pinnedParticipant: Binding<CallParticipant?>,
        onViewRendering: @escaping (VideoRenderer, CallParticipant) -> Void,
        onChangeTrackVisibility: @escaping @MainActor (CallParticipant, Bool) -> Void
    ) {
        self.viewFactory = viewFactory
        self.participant = participant
        self.size = size
        _pinnedParticipant = pinnedParticipant
        self.onViewRendering = onViewRendering
        self.onChangeTrackVisibility = onChangeTrackVisibility
    }
    
    public var body: some View {
        viewFactory.makeVideoParticipantView(
            participant: participant,
            availableSize: size,
            contentMode: .scaleAspectFit,
            onViewUpdate: { participant, view in
                onViewRendering(view, participant)
            }
        )
        .modifier(
            viewFactory.makeVideoCallParticipantModifier(
                participant: participant,
                participantCount: 1,
                pinnedParticipant: $pinnedParticipant,
                availableSize: size,
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
    }
    
    private var ratio: CGFloat {
        size.width / size.height
    }
}

struct ParticipantChangeModifier: ViewModifier {
    
    var participant: CallParticipant
    var onChangeTrackVisibility: @MainActor(CallParticipant, Bool) -> Void
    
    func body(content: Content) -> some View {
        if #available(iOS 14, *) {
            content
                .onChange(of: participant) { newValue in
                    log.debug("Participant \(newValue.name) is visible")
                    onChangeTrackVisibility(newValue, true)
                }
        } else {
            content
        }
    }
    
}
