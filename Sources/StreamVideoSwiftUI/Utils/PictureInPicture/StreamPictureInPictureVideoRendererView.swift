//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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

    /// The store managing Picture-in-Picture state.
    var store: PictureInPictureStore

    /// The participant whose video is being displayed.
    var participant: CallParticipant

    /// The video track to be rendered.
    var track: RTCVideoTrack?

    /// Creates a new Picture-in-Picture video renderer view.
    ///
    /// - Parameters:
    ///   - store: The store managing Picture-in-Picture state
    ///   - participant: The participant whose video is being displayed
    ///   - track: The video track to be rendered
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
    ///
    /// - Parameter context: The context in which the view is created
    /// - Returns: A configured `PictureInPictureVideoRenderer` instance
    func makeUIView(context: Context) -> PictureInPictureVideoRenderer {
        let result = PictureInPictureVideoRenderer(
            store: store,
            participant: participant,
            track: track
        )
        result.track = track
        return result
    }

    /// Updates the view when the video track changes.
    ///
    /// - Parameters:
    ///   - uiView: The view to update
    ///   - context: The context in which the update occurs
    func updateUIView(
        _ uiView: PictureInPictureVideoRenderer,
        context: Context
    ) {
        if uiView.track?.trackId != track?.trackId {
            uiView.track = track
        }
    }
}
