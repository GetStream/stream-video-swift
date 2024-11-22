//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import AVFoundation
import CoreMedia
import Foundation
import StreamWebRTC

final class CameraStopCaptureHandler: StreamVideoCapturerActionHandler, @unchecked Sendable {

    // MARK: - StreamVideoCapturerActionHandler

    func handle(_ action: StreamVideoCapturer.Action) async throws {
        switch action {
        case let .stopCapture(videoCapturer):
            guard
                let cameraVideoCapturer = videoCapturer as? RTCCameraVideoCapturer
            else {
                return
            }
            await execute(cameraVideoCapturer)
        default:
            break
        }
    }

    // MARK: - Private

    private func execute(_ videoCapturer: RTCCameraVideoCapturer) async {
        await withCheckedContinuation { continuation in
            videoCapturer.stopCapture {
                continuation.resume()
            }
        }
        log.debug("\(type(of: self)) stopped capturing.", subsystems: .videoCapturer)
    }
}
