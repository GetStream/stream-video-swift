//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
import StreamWebRTC
import SwiftUI

struct StreamPictureInPictureVideoRendererView: UIViewRepresentable {
    /// The type of the `UIView` being represented.
    typealias UIViewType = StreamPictureInPictureVideoRenderer

    var store: PictureInPictureStore

    var participant: CallParticipant

    var track: RTCVideoTrack?

    init(
        store: PictureInPictureStore,
        participant: CallParticipant,
        track: RTCVideoTrack?
    ) {
        self.store = store
        self.participant = participant
        self.track = track
    }

    func makeUIView(context: Context) -> StreamPictureInPictureVideoRenderer {
        let result = StreamPictureInPictureVideoRenderer(
            store: store,
            participant: participant,
            track: track
        )
        result.track = track
        return result
    }

    func updateUIView(
        _ uiView: StreamPictureInPictureVideoRenderer,
        context: Context
    ) {
        if uiView.track?.trackId != track?.trackId {
            uiView.track = track
        }
    }
}
