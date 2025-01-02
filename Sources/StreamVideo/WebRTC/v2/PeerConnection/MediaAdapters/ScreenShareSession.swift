//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// A structure representing a screen sharing session.
struct ScreenShareSession {
    /// The local video track for the screen share.
    var localTrack: RTCVideoTrack

    /// The type of screen sharing being performed.
    var screenSharingType: ScreensharingType

    /// The video capturer for the screen share.
    var capturer: VideoCapturing
}

/// A class that provides and manages the active screen sharing session.
final class ScreenShareSessionProvider {

    /// The currently active screen sharing session, if any.
    ///
    /// When set to nil, it automatically stops the capture of the previous session.
    var activeSession: ScreenShareSession? {
        didSet {
            if activeSession == nil {
                Task {
                    do {
                        try await oldValue?.capturer.stopCapture()
                    } catch {
                        log.error(error)
                    }
                }
            }
        }
    }

    /// Cleans up resources when the instance is deallocated.
    ///
    /// This deinitializer ensures that any active capture is stopped when the provider is destroyed.
    deinit {
        Task { [activeSession] in
            do {
                try await activeSession?.capturer.stopCapture()
            } catch {
                log.error(error)
            }
        }
    }
}
