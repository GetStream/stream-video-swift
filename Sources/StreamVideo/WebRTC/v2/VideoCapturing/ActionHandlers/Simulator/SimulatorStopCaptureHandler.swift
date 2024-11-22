//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

final class SimulatorStopCaptureHandler: StreamVideoCapturerActionHandler, @unchecked Sendable {

    // MARK: - StreamVideoCapturerActionHandler

    func handle(_ action: StreamVideoCapturer.Action) async throws {
        switch action {
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
