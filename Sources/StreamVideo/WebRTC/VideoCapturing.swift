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
    func capturingDevice(for cameraPosition: AVCaptureDevice.Position) -> AVCaptureDevice?
}
