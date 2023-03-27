//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI
import WebRTC

@MainActor
struct ParticipantsGridView<Factory: ViewFactory>: View {
    
    var viewFactory: Factory
    var participants: [CallParticipant]
    @Binding var pinnedParticipant: CallParticipant?
    var availableSize: CGSize
    var isPortrait: Bool
    var onViewUpdate: (CallParticipant, VideoRenderer) -> Void
    var participantVisibilityChanged: (CallParticipant, Bool) -> Void
    
    var body: some View {
        ScrollView {
            if #available(iOS 14.0, *) {
                LazyVGrid(
                    columns: [
                        .init(.adaptive(minimum: size.width, maximum: size.width), spacing: 0)
                    ],
                    spacing: 0
                ) {
                    participantsContent
                }
                .frame(maxWidth: availableSize.width, maxHeight: .infinity)
            } else {
                VStack {
                    participantsContent
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    private var participantsContent: some View {
        ForEach(participants) { participant in
            viewFactory.makeVideoParticipantView(
                participant: participant,
                availableSize: size,
                contentMode: .scaleAspectFill,
                onViewUpdate: onViewUpdate
            )
            .modifier(
                viewFactory.makeVideoCallParticipantModifier(
                    participant: participant,
                    participantCount: participants.count,
                    pinnedParticipant: $pinnedParticipant,
                    availableSize: size,
                    ratio: ratio
                )
            )
            .onAppear {
                log.debug("Participant \(participant.name) is visible")
                participantVisibilityChanged(participant, true)
            }
            .onDisappear {
                log.debug("Participant \(participant.name) is not visible")
                participantVisibilityChanged(participant, false)
            }
        }
    }
        
    var ratio: CGFloat {
        if isPortrait {
            let width = availableSize.width / 2
            let height = availableSize.height / 3
            return width / height
        } else {
            let width = availableSize.width / 3
            let height = availableSize.height / 2
            return width / height
        }
    }
    
    private var size: CGSize {
        if #available(iOS 14.0, *) {
            let dividerWidth: CGFloat = isPortrait ? 2 : 3
            return CGSize(width: availableSize.width / dividerWidth, height: availableSize.height / 2)
        } else {
            return CGSize(width: availableSize.width, height: availableSize.height / 2)
        }
    }
}
