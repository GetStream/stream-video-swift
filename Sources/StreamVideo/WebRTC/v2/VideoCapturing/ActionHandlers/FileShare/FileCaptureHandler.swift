//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class FileCaptureHandler: StreamVideoCapturerActionHandler, @unchecked Sendable {

    // MARK: - StreamVideoCapturerActionHandler

    /// Handles simulator capture actions.
    func handle(_ action: StreamVideoCapturer.Action) async throws {
        switch action {
        case let .startCapture(_, _, _, _, videoCapturer, _, _):
            guard let fileCapturer = videoCapturer as? FileScreenCapturer else {
                return
            }
            fileCapturer.startCapturing()
            
        case let .stopCapture(videoCapturer):
            guard let fileCapturer = videoCapturer as? FileScreenCapturer else {
                return
            }
            fileCapturer.stopCapturing()
        default:
            break
        }
    }
}
