//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
    var viewFactory: PictureInPictureViewFactory
    var participant: CallParticipant
    var track: RTCVideoTrack?

    @State private var isUsingFrontCameraForLocalUser: Bool = false

    /// Creates a new participant view.
    ///
    /// - Parameters:
    ///   - store: The store managing Picture-in-Picture state
    ///   - viewFactory: Factory for creating views
    ///   - participant: The participant to display
    ///   - track: The participant's video track
    init(
        store: PictureInPictureStore,
        viewFactory: PictureInPictureViewFactory,
        participant: CallParticipant,
        track: RTCVideoTrack?
    ) {
        self.store = store
        self.viewFactory = viewFactory
        self.participant = participant
        self.track = track
    }

    var body: some View {
        withCallSettingsObservation {
            PictureInPictureVideoRendererView(
                store: store,
                participant: participant,
                track: track
            )
        }
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
        viewFactory
            .makeParticipantImageView(participant: participant)
            .opacity(showVideo ? 0 : 1)
    }

    @MainActor
    @ViewBuilder
    private func withCallSettingsObservation(
        @ViewBuilder _ content: () -> some View
    ) -> some View {
        if participant.sessionId == streamVideo.state.activeCall?.state.localParticipant?.sessionId {
            Group {
                if isUsingFrontCameraForLocalUser {
                    content()
                        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                } else {
                    content()
                }
            }
            .onReceive(store.state.call?.state.$callSettings) {
                self.isUsingFrontCameraForLocalUser = $0.cameraPosition == .front
            }
        } else {
            content()
        }
    }
}
