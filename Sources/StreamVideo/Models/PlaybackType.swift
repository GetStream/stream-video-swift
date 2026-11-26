//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// How the backend routed a joined call to the client.
///
/// The backend picks the route on the first join. The call state returns to
/// `webRTC` when the call ends. Read it from ``CallState/playbackType``.
///
/// When the backend does not grant HLS, the client joins over WebRTC.
///
/// - Important: This API is in beta. Future releases can add cases, so keep a
///   `default` when you switch over it.
public enum PlaybackType: Equatable, Sendable {

    /// The client is connected to the call through WebRTC.
    case webRTC

    /// The client plays the call as an HLS stream from the given playlist URL.
    ///
    /// The client has no SFU connection in this mode, so the call has no
    /// participants or tracks, and it never publishes. The client leaves when
    /// the call ends, or when the call goes to backstage and the user has no
    /// `join-backstage` capability. Use `HLSVideoRenderer` or ``HLSPlayback``
    /// to play the stream, or use the URL with a player such as `AVPlayer`.
    case hls(URL)
}
