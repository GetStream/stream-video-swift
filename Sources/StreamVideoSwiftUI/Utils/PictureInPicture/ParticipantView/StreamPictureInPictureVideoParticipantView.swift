//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
import StreamWebRTC
import SwiftUI

struct StreamPictureInPictureVideoParticipantView: View {

    @Injected(\.images) var images
    @Injected(\.streamVideo) var streamVideo

    var store: PictureInPictureStore
    var viewFactory: AnyViewFactory
    var participant: CallParticipant
    var track: RTCVideoTrack?

    init(
        store: PictureInPictureStore,
        viewFactory: AnyViewFactory,
        participant: CallParticipant,
        track: RTCVideoTrack?
    ) {
        self.store = store
        self.viewFactory = viewFactory
        self.participant = participant
        self.track = track
    }

    var body: some View {
        StreamPictureInPictureVideoRendererView(
            store: store,
            participant: participant,
            track: track
        )
        .opacity(showVideo ? 1 : 0)
        .streamAccessibility(value: showVideo ? "1" : "0")
        .overlay(overlayView)
        .pictureInPictureParticipant(participant: participant, call: store.state.call)
    }

    private var showVideo: Bool { participant.shouldDisplayTrack }

    @ViewBuilder
    private var overlayView: some View {
        CallParticipantImageView(
            viewFactory: viewFactory,
            id: participant.id,
            name: participant.name,
            imageURL: participant.profileImageURL
        )
        .opacity(showVideo ? 0 : 1)
    }
}
