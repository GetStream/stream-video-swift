//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

protocol VideoCapturing {
    func startCapture(device: AVCaptureDevice?) async throws
    func stopCapture() async throws
}

protocol CameraVideoCapturing: VideoCapturing {
    func setCameraPosition(_ cameraPosition: AVCaptureDevice.Position) async throws
    func setVideoFilter(_ videoFilter: VideoFilter?)
    func updateCaptureQuality(
        _ codecs: [VideoCodec],
        on device: AVCaptureDevice?
    ) async throws
    func capturingDevice(for cameraPosition: AVCaptureDevice.Position) -> AVCaptureDevice?
    func zoom(by factor: CGFloat) throws
    func focus(at point: CGPoint) throws
    func addVideoOutput(
        _ videoOutput: AVCaptureVideoDataOutput
    ) throws
    func removeVideoOutput(
        _ videoOutput: AVCaptureVideoDataOutput
    ) throws
    func addCapturePhotoOutput(
        _ capturePhotoOutput: AVCapturePhotoOutput
    ) throws
    func removeCapturePhotoOutput(
        _ capturePhotoOutput: AVCapturePhotoOutput
    ) throws
}
