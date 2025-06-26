//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

struct VideoParticipantsViewLandscape<Factory: ViewFactory>: View {
    
    var viewFactory: Factory
    var call: Call?
    var participants: [CallParticipant]
    var availableFrame: CGRect
    var onChangeTrackVisibility: @MainActor(CallParticipant, Bool) -> Void
    
    var body: some View {
        ZStack {
            if participants.count <= 3 {
                HorizontalParticipantsView(
                    viewFactory: viewFactory,
                    call: call,
                    participants: participants,
                    availableFrame: availableFrame,
                    onChangeTrackVisibility: onChangeTrackVisibility
                )
            } else if participants.count == 4 {
                TwoRowParticipantsView(
                    viewFactory: viewFactory,
                    call: call,
                    firstRowParticipants: [participants[0], participants[1]],
                    secondRowParticipants: [participants[2], participants[3]],
                    availableFrame: availableFrame,
                    onChangeTrackVisibility: onChangeTrackVisibility
                )
            } else if participants.count == 5 {
                TwoRowParticipantsView(
                    viewFactory: viewFactory,
                    call: call,
                    firstRowParticipants: [participants[0], participants[1]],
                    secondRowParticipants: [participants[2], participants[3], participants[4]],
                    availableFrame: availableFrame,
                    onChangeTrackVisibility: onChangeTrackVisibility
                )
            } else {
                ParticipantsGridView(
                    viewFactory: viewFactory,
                    call: call,
                    participants: participants,
                    availableFrame: availableFrame,
                    isPortrait: false,
                    participantVisibilityChanged: { participant, isVisible in
                        onChangeTrackVisibility(participant, isVisible)
                    }
                )
            }
        }
        .debugViewRendering()
    }
}
