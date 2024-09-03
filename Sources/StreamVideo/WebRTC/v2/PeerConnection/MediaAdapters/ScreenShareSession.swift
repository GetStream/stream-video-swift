//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

struct ScreenShareSession {
    var localTrack: RTCVideoTrack
    var screenSharingType: ScreensharingType
    var capturer: VideoCapturing
}

final class ScreenShareSessionProvider {
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
