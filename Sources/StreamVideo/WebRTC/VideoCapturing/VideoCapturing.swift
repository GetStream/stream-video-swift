//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

struct VideoCapturingConfiguration: Equatable {
    var position: AVCaptureDevice.Position
    var dimensions: CGSize
    var frameRate: Int
}

protocol VideoCapturing {
    func startCapture(with configuration: VideoCapturingConfiguration) async throws
    func stopCapture() async throws
}

protocol CameraVideoCapturing: VideoCapturing {
    func setCameraPosition(_ cameraPosition: AVCaptureDevice.Position) async throws
    func setVideoFilter(_ videoFilter: VideoFilter?)
    func updateCaptureQuality(
        _ codecs: [VideoLayer],
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
