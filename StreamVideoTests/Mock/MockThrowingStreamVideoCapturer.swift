//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
@testable import StreamVideo
import StreamWebRTC

enum MockThrowingStreamVideoCapturerError: Error, Equatable {
    case startCaptureFailed
    case stopCaptureFailed
}

final class MockThrowingStreamVideoCapturer: StreamVideoCapturing, @unchecked Sendable {
    let shouldThrowOnStartCapture: Bool
    let shouldThrowOnStopCapture: Bool

    init(
        shouldThrowOnStartCapture: Bool = false,
        shouldThrowOnStopCapture: Bool = false
    ) {
        self.shouldThrowOnStartCapture = shouldThrowOnStartCapture
        self.shouldThrowOnStopCapture = shouldThrowOnStopCapture
    }

    func supportsBackgrounding() async -> Bool {
        false
    }

    func startCapture(
        position: AVCaptureDevice.Position,
        dimensions: CGSize,
        frameRate: Int
    ) async throws {
        if shouldThrowOnStartCapture {
            throw MockThrowingStreamVideoCapturerError.startCaptureFailed
        }
    }

    func stopCapture() async throws {
        if shouldThrowOnStopCapture {
            throw MockThrowingStreamVideoCapturerError.stopCaptureFailed
        }
    }

    func setCameraPosition(_ position: AVCaptureDevice.Position) async throws {
        if false { _ = position }
    }

    func setVideoFilter(_ videoFilter: VideoFilter?) async {}

    func updateCaptureQuality(_ dimensions: CGSize) async throws {}

    func focus(at point: CGPoint) async throws {}

    func zoom(by factor: CGFloat) async throws {}

    func addCapturePhotoOutput(
        _ capturePhotoOutput: AVCapturePhotoOutput
    ) async throws {}

    func removeCapturePhotoOutput(
        _ capturePhotoOutput: AVCapturePhotoOutput
    ) async throws {}

    func addVideoOutput(_ videoOutput: AVCaptureVideoDataOutput) async throws {}

    func removeVideoOutput(_ videoOutput: AVCaptureVideoDataOutput) async throws {}
}
