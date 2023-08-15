//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI
import WebRTC

public struct ParticipantsFullScreenLayout<Factory: ViewFactory>: View {
    
    var viewFactory: Factory
    var participant: CallParticipant
    var call: Call?
    var size: CGSize
    var onChangeTrackVisibility: @MainActor(CallParticipant, Bool) -> Void
    
    public init(
        viewFactory: Factory,
        participant: CallParticipant,
        call: Call?,
        size: CGSize,
        onChangeTrackVisibility: @escaping @MainActor (CallParticipant, Bool) -> Void
    ) {
        self.viewFactory = viewFactory
        self.participant = participant
        self.call = call
        self.size = size
        self.onChangeTrackVisibility = onChangeTrackVisibility
    }
    
    public var body: some View {
        viewFactory.makeVideoParticipantView(
            participant: participant,
            id: participant.id,
            availableSize: size,
            contentMode: .scaleAspectFit,
            customData: [:],
            call: call
        )
        .modifier(
            viewFactory.makeVideoCallParticipantModifier(
                participant: participant,
                call: call,
                availableSize: size,
                ratio: ratio,
                showAllInfo: true
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
