//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
import StreamWebRTC
import SwiftUI

struct StreamPictureInPictureScreenSharingView: View {
    
    @Injected(\.images) var images
    @Injected(\.streamVideo) var streamVideo

    var store: PictureInPictureStore
    var viewFactory: AnyViewFactory
    var participant: CallParticipant
    var track: RTCVideoTrack

    init(
        store: PictureInPictureStore,
        viewFactory: AnyViewFactory,
        participant: CallParticipant,
        track: RTCVideoTrack
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
        .pictureInPictureParticipant(participant: participant, call: store.state.call)
    }
}
