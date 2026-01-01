//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamWebRTC

/// Extension adding cloning functionality to `RTCAudioTrack`.
///
/// This extension provides a method to create a duplicate of an existing
/// `RTCAudioTrack`, preserving its enabled state.
extension RTCAudioTrack {

    /// Creates a clone of the current audio track using the specified factory.
    ///
    /// - Parameter factory: A `PeerConnectionFactory` used to create the new
    ///   audio track. The factory provides the required audio source.
    /// - Returns: A new `RTCAudioTrack` instance that duplicates the current
    ///   track's state, including whether it is enabled or disabled.
    ///
    /// - Note:
    ///   - The cloned track uses the same audio source as the original track.
    ///   - This method is useful when multiple tracks with the same source
    ///     are needed for different transceivers or streams.
    func clone(from factory: PeerConnectionFactory) -> RTCAudioTrack {
        // Create a new audio track using the same audio source.
        let result = factory.makeAudioTrack(source: source)

        // Preserve the enabled state of the original track.
        result.isEnabled = isEnabled

        return result
    }
}
