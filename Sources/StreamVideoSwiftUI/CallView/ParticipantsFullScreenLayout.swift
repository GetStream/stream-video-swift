//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamWebRTC
import SwiftUI

public struct ParticipantsFullScreenLayout<Factory: ViewFactory>: View {
    
    var viewFactory: Factory
    var participant: CallParticipant
    var call: Call?
    var frame: CGRect
    var onChangeTrackVisibility: @MainActor (CallParticipant, Bool) -> Void
    
    public init(
        viewFactory: Factory = DefaultViewFactory.shared,
        participant: CallParticipant,
        call: Call?,
        frame: CGRect,
        onChangeTrackVisibility: @escaping @MainActor (CallParticipant, Bool) -> Void
    ) {
        self.viewFactory = viewFactory
        self.participant = participant
        self.call = call
        self.frame = frame
        self.onChangeTrackVisibility = onChangeTrackVisibility
    }
    
    public var body: some View {
        viewFactory.makeVideoParticipantView(
            participant: participant,
            id: participant.id,
            availableFrame: frame,
            contentMode: .scaleAspectFit,
            customData: [:],
            call: call
        )
        .modifier(
            viewFactory.makeVideoCallParticipantModifier(
                participant: participant,
                call: call,
                availableFrame: frame,
                ratio: ratio,
                showAllInfo: true
            )
        )
        .onAppear {
            log.debug("Participant \(participant.name) is visible")
            onChangeTrackVisibility(participant, true)
        }
        .modifier(
            ParticipantChangeModifier(
                participant: participant,
                onChangeTrackVisibility: onChangeTrackVisibility
            )
        )
    }
    
    private var ratio: CGFloat {
        frame.size.width / frame.size.height
    }
}

struct ParticipantChangeModifier: ViewModifier {
    
    var participant: CallParticipant
    var onChangeTrackVisibility: @MainActor (CallParticipant, Bool) -> Void
    
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
