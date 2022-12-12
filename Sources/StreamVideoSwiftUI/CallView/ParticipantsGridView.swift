//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI
import WebRTC

struct ParticipantsGridView: View {
    
    var participants: [CallParticipant]
    var availableSize: CGSize
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
            VideoCallParticipantView(
                participant: participant,
                availableSize: size,
                onViewUpdate: onViewUpdate
            )
            .adjustVideoFrame(to: size.width, ratio: 0.3)
            .overlay(
                AudioIndicatorView(participant: participant)
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
    
    private var size: CGSize {
        if #available(iOS 14.0, *) {
            return CGSize(width: availableSize.width / 2, height: availableSize.height / 2)
        } else {
            return CGSize(width: availableSize.width, height: availableSize.height / 2)
        }
    }
}
