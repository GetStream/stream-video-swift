//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

struct VideoParticipantsViewPortrait<Factory: ViewFactory>: View {
    
    var viewFactory: Factory
    var call: Call?
    var participants: [CallParticipant]
    var availableFrame: CGRect
    var onChangeTrackVisibility: @MainActor(CallParticipant, Bool) -> Void
    
    var body: some View {
        ZStack {
            if participants.count <= 3 {
                VerticalParticipantsView(
                    viewFactory: viewFactory,
                    call: call,
                    participants: participants,
                    availableFrame: availableFrame,
                    onChangeTrackVisibility: onChangeTrackVisibility
                )
            } else if participants.count == 4 {
                TwoColumnParticipantsView(
                    viewFactory: viewFactory,
                    call: call,
                    leftColumnParticipants: [participants[0], participants[2]],
                    rightColumnParticipants: [participants[1], participants[3]],
                    availableFrame: availableFrame,
                    onChangeTrackVisibility: onChangeTrackVisibility
                )
            } else if participants.count == 5 {
                TwoColumnParticipantsView(
                    viewFactory: viewFactory,
                    call: call,
                    leftColumnParticipants: [participants[0], participants[2], participants[4]],
                    rightColumnParticipants: [participants[1], participants[3]],
                    availableFrame: availableFrame,
                    onChangeTrackVisibility: onChangeTrackVisibility
                )
            } else {
                ParticipantsGridView(
                    viewFactory: viewFactory,
                    call: call,
                    participants: participants,
                    availableFrame: availableFrame,
                    isPortrait: true,
                    participantVisibilityChanged: { participant, isVisible in
                        onChangeTrackVisibility(participant, isVisible)
                    }
                )
            }
        }
    }
}
