//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI
import WebRTC

struct ParticipantsGridView: View {
    
    var participants: [CallParticipant]
    var availableSize: CGSize
    var onViewUpdate: (CallParticipant, StreamMTLVideoView) -> Void
    var participantVisibilityChanged: (CallParticipant, Bool) -> Void
    
    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    .init(.adaptive(minimum: size.width, maximum: size.width), spacing: 0)
                ],
                spacing: 0
            ) {
                ForEach(participants) { participant in
                    VideoCallParticipantView(
                        participant: participant,
                        availableSize: size,
                        onViewUpdate: onViewUpdate
                    )
                    .adjustVideoFrame(to: size, ratio: 0.3)
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
            .frame(maxWidth: availableSize.width, maxHeight: .infinity)
        }
        .edgesIgnoringSafeArea(.vertical)
    }
    
    private var size: CGSize {
        CGSize(width: availableSize.width / 2, height: availableSize.height / 2)
    }
}
