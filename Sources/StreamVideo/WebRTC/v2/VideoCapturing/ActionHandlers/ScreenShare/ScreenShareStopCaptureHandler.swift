//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import ReplayKit
import StreamWebRTC

final class ScreenShareStopCaptureHandler: StreamVideoCapturerActionHandler, @unchecked Sendable {

    private let recorder: RPScreenRecorder

    init(
        recorder: RPScreenRecorder = .shared()
    ) {
        self.recorder = recorder
    }

    // MARK: - StreamVideoCapturerActionHandler

    func handle(_ action: StreamVideoCapturer.Action) async throws {
        switch action {
        case .stopCapture:
            try await execute()
        default:
            break
        }
    }

    // MARK: - Private

    private func execute() async throws {
        try await withCheckedThrowingContinuation { [weak self] continuation in
            guard
                let recorder = self?.recorder,
                recorder.isRecording
            else {
                continuation.resume()
                return
            }

            recorder.stopCapture { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
