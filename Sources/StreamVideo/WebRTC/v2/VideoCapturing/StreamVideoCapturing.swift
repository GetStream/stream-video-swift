//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

protocol StreamVideoCapturing: AnyObject, Sendable {
    func supportsBackgrounding() async -> Bool

    func startCapture(
        position: AVCaptureDevice.Position,
        dimensions: CGSize,
        frameRate: Int
    ) async throws

    func stopCapture() async throws

    func setCameraPosition(_ position: AVCaptureDevice.Position) async throws

    func setVideoFilter(_ videoFilter: VideoFilter?) async

    func updateCaptureQuality(
        _ dimensions: CGSize
    ) async throws

    func focus(at point: CGPoint) async throws

    func zoom(by factor: CGFloat) async throws

    func addCapturePhotoOutput(
        _ capturePhotoOutput: AVCapturePhotoOutput
    ) async throws

    func removeCapturePhotoOutput(
        _ capturePhotoOutput: AVCapturePhotoOutput
    ) async throws

    func addVideoOutput(
        _ videoOutput: AVCaptureVideoDataOutput
    ) async throws

    func removeVideoOutput(
        _ videoOutput: AVCaptureVideoDataOutput
    ) async throws
}
