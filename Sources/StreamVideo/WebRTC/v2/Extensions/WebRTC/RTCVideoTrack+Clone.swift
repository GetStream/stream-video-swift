//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamWebRTC

/// Extension adding cloning functionality to `RTCVideoTrack`.
///
/// This extension provides a method to create a duplicate of an existing
/// `RTCVideoTrack`, preserving its enabled state.
extension RTCVideoTrack {

    /// Creates a clone of the current video track using the specified factory.
    ///
    /// - Parameter factory: A `PeerConnectionFactory` used to create the new
    ///   video track. The factory provides the required video source.
    /// - Returns: A new `RTCVideoTrack` instance that duplicates the current
    ///   track's state, including whether it is enabled or disabled.
    ///
    /// - Note:
    ///   - The cloned track uses the same video source as the original track.
    ///   - This method is useful when multiple tracks with the same source
    ///     are needed for different transceivers or streams.
    func clone(from factory: PeerConnectionFactory) -> RTCVideoTrack {
        // Create a new video track using the same video source.
        let result = factory.makeVideoTrack(source: source)

        // Preserve the enabled state of the original track.
        result.isEnabled = isEnabled

        return result
    }
}
