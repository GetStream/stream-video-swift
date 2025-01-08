//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation

protocol CaptureDeviceProtocol {
    var position: AVCaptureDevice.Position { get }

    func outputFormat(
        preferredDimensions: CMVideoDimensions,
        preferredFrameRate: Int
    ) -> AVCaptureDevice.Format?
}

extension AVCaptureDevice: CaptureDeviceProtocol {}
