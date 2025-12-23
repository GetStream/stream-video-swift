//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

final class SimulatorCaptureHandler: StreamVideoCapturerActionHandler, @unchecked Sendable {

    // MARK: - StreamVideoCapturerActionHandler

    /// Handles simulator capture actions.
    func handle(_ action: StreamVideoCapturer.Action) async throws {
        switch action {
        case let .startCapture(_, _, _, _, videoCapturer, _, _):
            guard let simulatorCapturer = videoCapturer as? SimulatorScreenCapturer else {
                return
            }
            simulatorCapturer.startCapturing()
        case let .stopCapture(videoCapturer):
            guard let simulatorCapturer = videoCapturer as? SimulatorScreenCapturer else {
                return
            }
            simulatorCapturer.stopCapturing()
        default:
            break
        }
    }
}
