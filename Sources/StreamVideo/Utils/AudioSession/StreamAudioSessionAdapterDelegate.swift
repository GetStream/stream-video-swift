//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A delegate protocol for receiving updates related to the audio session's
/// call settings.
protocol StreamAudioSessionAdapterDelegate: AnyObject {
    /// Called when the audio session updates its call settings.
    /// - Parameters:
    ///   - audioSession: The `AudioSession` instance that made the update.
    ///   - callSettings: The updated `CallSettings`.
    func audioSessionAdapterDidUpdateSpeakerOn(
        _ speakerOn: Bool,
        file: StaticString,
        function: StaticString,
        line: UInt
    )
}
