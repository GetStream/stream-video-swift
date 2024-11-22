//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import ReplayKit
import StreamWebRTC

final class BroadcastStopCaptureHandler: StreamVideoCapturerActionHandler, @unchecked Sendable {

    @Injected(\.broadcastBufferReader) private var broadcastBufferReader

    // MARK: - StreamVideoCapturerActionHandler

    func handle(_ action: StreamVideoCapturer.Action) async throws {
        switch action {
        case .stopCapture:
            broadcastBufferReader.stopCapturing()
            log.debug("\(type(of: self)) stopped capturing.", subsystems: .videoCapturer)
        default:
            break
        }
    }
}
