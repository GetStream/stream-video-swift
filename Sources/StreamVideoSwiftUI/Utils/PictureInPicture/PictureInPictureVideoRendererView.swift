//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
import StreamWebRTC
import SwiftUI

/// A SwiftUI wrapper for the Picture-in-Picture video renderer.
///
/// Bridges SwiftUI with UIKit to display video content in the Picture-in-Picture window.
struct PictureInPictureVideoRendererView: UIViewRepresentable {
    /// The type of the `UIView` being represented.
    typealias UIViewType = PictureInPictureVideoRenderer

    var store: PictureInPictureStore
    var participant: CallParticipant
    var track: RTCVideoTrack?

    /// Creates a new video renderer view.
    ///
    /// - Parameters:
    ///   - store: The store managing Picture-in-Picture state
    ///   - participant: The participant whose video to display
    ///   - track: The video track to render
    init(
        store: PictureInPictureStore,
        participant: CallParticipant,
        track: RTCVideoTrack?
    ) {
        self.store = store
        self.participant = participant
        self.track = track
    }

    /// Creates the underlying UIKit view.
    func makeUIView(context: Context) -> PictureInPictureVideoRenderer {
        let result = PictureInPictureVideoRenderer(
            store: store,
            participant: participant,
            track: track
        )
        return result
    }

    /// Updates the view when the video track changes.
    func updateUIView(
        _ uiView: PictureInPictureVideoRenderer,
        context: Context
    ) {
        if uiView.participant != participant {
            uiView.participant = participant
        }
        if uiView.track?.trackId != track?.trackId {
            uiView.track = track
        }
    }
}
