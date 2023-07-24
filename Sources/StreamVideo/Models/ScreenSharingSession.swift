//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import WebRTC

public struct ScreenSharingSession {
    public let track: RTCVideoTrack?
    public let participant: CallParticipant
}

public enum ScreensharingType: Sendable {
    case inApp
    case broadcast
}
