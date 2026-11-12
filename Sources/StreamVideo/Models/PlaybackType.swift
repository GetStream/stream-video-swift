//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// How the backend routed a joined call to the client.
///
/// The backend picks the route when the client joins. The route does not
/// change for the lifetime of the call.
public enum PlaybackType: Equatable, Sendable {

    /// The client is connected to the call through WebRTC.
    case webRTC

    /// The client plays the call as an HLS stream from the given playlist URL.
    ///
    /// The client has no SFU connection in this mode, so the call has no
    /// participants or tracks. Use the URL with a player such as `AVPlayer`.
    case hls(URL)
}
