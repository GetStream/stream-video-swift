//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
import StreamWebRTC
import SwiftUI

/// Displays a participant's screen share in the Picture-in-Picture window.
///
/// Renders the screen sharing content with participant information overlay.
struct PictureInPictureScreenSharingView: View {
    
    @Injected(\.images) var images
    @Injected(\.streamVideo) var streamVideo

    var store: PictureInPictureStore
    var participant: CallParticipant
    var track: RTCVideoTrack

    /// Creates a new screen sharing view.
    ///
    /// - Parameters:
    ///   - store: The store managing Picture-in-Picture state
    ///   - participant: The participant sharing their screen
    ///   - track: The screen sharing video track
    init(
        store: PictureInPictureStore,
        participant: CallParticipant,
        track: RTCVideoTrack
    ) {
        self.store = store
        self.participant = participant
        self.track = track
    }
    
    var body: some View {
        PictureInPictureVideoRendererView(
            store: store,
            participant: participant,
            track: track
        )
        .pictureInPictureParticipant(participant: participant, call: store.state.call)
    }
}
