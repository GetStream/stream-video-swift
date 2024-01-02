//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamVideo
import StreamVideoSwiftUI

struct ReactionOverlayView: View {

    @ObservedObject var reactionsHelper = AppState.shared.reactionsHelper

    var participant: CallParticipant

    var body: some View {
        if let firstReaction = reactionsHelper
            .activeReactions[participant.userId]?
            .last 
        {
            reactionView(for: firstReaction)
        } else {
            EmptyView()
        }
    }


    @ViewBuilder
    private func reactionView(for reaction: Reaction) -> some View {
        ZStack {
            TopRightView {
                ReactionIcon(iconName: reaction.iconName)
            }
        }
        .padding(.horizontal)
    }
}

struct ReactionOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        AppState.shared
            .reactionsHelper
            .activeReactions["preview-participant"] = [.raiseHand]

        return ReactionOverlayView(
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
            )
        )
    }
}
