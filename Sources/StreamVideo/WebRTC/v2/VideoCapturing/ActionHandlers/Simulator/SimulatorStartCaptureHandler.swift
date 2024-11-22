//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

final class SimulatorStartCaptureHandler: StreamVideoCapturerActionHandler, @unchecked Sendable {

    // MARK: - StreamVideoCapturerActionHandler

    func handle(_ action: StreamVideoCapturer.Action) async throws {
        switch action {
        case let .startCapture(_, _, _, _, videoCapturer, _):
            guard let simulatorCapturer = videoCapturer as? SimulatorScreenCapturer else {
                return
            }
            simulatorCapturer.startCapturing()
        default:
            break
        }
    }
}
