//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
import StreamWebRTC
import SwiftUI

/// Displays a participant's video in the Picture-in-Picture window.
///
/// Shows either the participant's video feed or their profile image if video is not available.
struct PictureInPictureVideoParticipantView: View {

    @Injected(\.images) var images
    @Injected(\.streamVideo) var streamVideo

    var store: PictureInPictureStore
    var viewFactory: AnyViewFactory
    var participant: CallParticipant
    var track: RTCVideoTrack?

    /// Creates a new participant view.
    ///
    /// - Parameters:
    ///   - store: The store managing Picture-in-Picture state
    ///   - viewFactory: Factory for creating views
    ///   - participant: The participant to display
    ///   - track: The participant's video track
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
        PictureInPictureVideoRendererView(
            store: store,
            participant: participant,
            track: track
        )
        .opacity(showVideo ? 1 : 0)
        .streamAccessibility(value: showVideo ? "1" : "0")
        .overlay(overlayView)
        .pictureInPictureParticipant(participant: participant, call: store.state.call)
    }

    /// Whether the participant's video should be displayed.
    private var showVideo: Bool { participant.shouldDisplayTrack }

    /// The overlay view showing participant information.
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
