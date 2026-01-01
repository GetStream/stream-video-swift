//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct ReactionOverlayView: View {

    @ObservedObject var reactionsAdapter = InjectedValues[\.reactionsAdapter]

    var participant: CallParticipant

    var body: some View {
        if let firstReaction = reactionsAdapter
            .activeReactions[participant.userId]?
            .last {
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
        InjectedValues[\.reactionsAdapter].activeReactions["preview-participant"] = [
            .raiseHand
        ]

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
                pin: nil,
                pausedTracks: []
            )
        )
    }
}
