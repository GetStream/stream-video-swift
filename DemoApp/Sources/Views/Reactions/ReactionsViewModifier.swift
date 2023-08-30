//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamVideo

struct ReactionsViewModifier: ViewModifier {

    @ObservedObject var reactionsHelper = AppState.shared.reactionsHelper

    var participant: CallParticipant
    var availableSize: CGSize

    func body(content: Content) -> some View {
        content
            .overlay(
                ReactionOverlayView(participant: participant, availableSize: availableSize)
            )
            .onChange(of: participant.isSpeaking) { newValue in
                if newValue {
                    reactionsHelper.removeRaisedHand(from: participant.userId)
                }
            }
    }
}


struct ReactionsViewModifier_Previews: PreviewProvider {
    static var previews: some View {
        AppState.shared.reactionsHelper.activeReactions["preview-participant"] = [.raiseHand]

        return Color.white.modifier(
            ReactionsViewModifier(
                reactionsHelper: AppState.shared.reactionsHelper,
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
                    pin: nil
                ),
                availableSize: .init(width: 1024, height: 768)
            )
        )
    }
}
