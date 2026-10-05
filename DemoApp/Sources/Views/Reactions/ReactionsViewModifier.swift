//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct ReactionsViewModifier: ViewModifier {

    @Injected(\.layout) private var layout
    @ObservedObject var reactionsAdapter = InjectedValues[\.reactionsAdapter]
    
    var participant: CallParticipant
    
    func body(content: Content) -> some View {
        content
            .overlay(
                ReactionOverlayView(
                    participant: participant
                )
                .padding(.top, layout.spacingMd)
            )
            .onChange(of: participant.isSpeaking) { newValue in
                if newValue {
                    reactionsAdapter.removeRaisedHand(from: participant.userId)
                }
            }
    }
}

struct ReactionsViewModifier_Previews: PreviewProvider {
    static var previews: some View {
        let reactionsAdapter = InjectedValues[\.reactionsAdapter]
        reactionsAdapter.activeReactions["preview-participant"] = [
            .raiseHand
        ]
        
        return Color
            .white
            .modifier(
                ReactionsViewModifier(
                    participant: .init(
                        id: "preview-participant",
                        userId: "preview-participant",
                        roles: [],
                        name: "preview-participant",
                        profileImageURL: nil,
                        trackLookupPrefix: nil,
                        hasVideo: false,
                        hasAudio: false,
                        isScreenSharing: false,
                        showTrack: false,
                        isDominantSpeaker: false,
                        sessionId: "preview",
                        connectionQuality: .unknown,
                        joinedAt: Date(),
                        audioLevel: 0,
                        audioLevels: [],
                        pin: nil,
                        pausedTracks: []
                    )
                )
            )
    }
}
