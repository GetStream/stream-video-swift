//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

public struct ScreenSharingSession {
    public let track: RTCVideoTrack?
    public let participant: CallParticipant
}

public enum ScreensharingType: Sendable {
    /// Screensharing only the app window.
    case inApp
    /// Screensharing even when the app is in background.
    case broadcast
}
