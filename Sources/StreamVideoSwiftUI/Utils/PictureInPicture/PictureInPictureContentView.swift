//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
import SwiftUI

/// Displays the appropriate content in the Picture-in-Picture window.
///
/// This view handles rendering different types of content based on the current state,
/// including participant video, screen sharing, and reconnection states.
struct PictureInPictureContentView: View {

    @Injected(\.appearance) private var appearance

    private let store: PictureInPictureStore

    @State private var state: PictureInPictureContent
    @State private var viewFactory: PictureInPictureViewFactory

    /// Creates a new Picture-in-Picture content view.
    ///
    /// - Parameter store: The store managing Picture-in-Picture state
    init(
        store: PictureInPictureStore
    ) {
        self.store = store
        viewFactory = store.state.viewFactory
        state = store.state.content
    }

    var body: some View {
        ZStack {
            Color(appearance.colors.participantBackground)
                .edgesIgnoringSafeArea(.all)

            contentView
        }
        .edgesIgnoringSafeArea(.all)
        .onReceive(store.publisher(for: \.viewFactory)) { viewFactory = $0 }
        .onReceive(store.publisher(for: \.content)) { state = $0 }
    }

    /// The main content view that switches between different states.
    @ViewBuilder
    private var contentView: some View {
        switch state {
        case .inactive:
            EmptyView()
        case let .participant(_, participant, track):
            PictureInPictureVideoParticipantView(
                store: store,
                viewFactory: viewFactory,
                participant: participant,
                track: track
            )
        case let .screenSharing(_, participant, track):
            PictureInPictureScreenSharingView(
                store: store,
                participant: participant,
                track: track
            )
        case .reconnecting:
            PictureInPictureReconnectionView()
        }
    }
}
