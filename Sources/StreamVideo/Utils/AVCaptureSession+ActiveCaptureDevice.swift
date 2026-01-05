//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

extension AVCaptureSession {
    var activeVideoCaptureDevice: AVCaptureDevice? {
        inputs
            .lazy
            .compactMap { ($0 as? AVCaptureDeviceInput)?.device }
            .first { $0.hasMediaType(.video) }
    }
}
