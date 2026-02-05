//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

public struct ScreenSharingSession {
    public let track: RTCVideoTrack?
    public let participant: CallParticipant
}

public enum ScreensharingType: Sendable, Equatable {
    /// Screensharing only the app window.
    case inApp
    /// Screensharing even when the app is in background.
    case broadcast

    case custom(URL)
}

extension ScreensharingType {
    public static func == (
        lhs: ScreensharingType,
        rhs: ScreensharingType
    ) -> Bool {
        switch (lhs, rhs) {
        case (.inApp, .inApp):
            return true
        case (.broadcast, .broadcast):
            return true
        case let (.custom(leftURL), .custom(rightURL)):
            return leftURL == rightURL
        default:
            return false
        }
    }
}
