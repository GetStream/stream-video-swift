//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@preconcurrency import StreamWebRTC

/// Configuration for the video options for a call.
struct VideoOptions: Sendable {
    /// The preferred video format.
    var preferredFormat: AVCaptureDevice.Format?
    var preferredCameraPosition: AVCaptureDevice.Position

    init(
        preferredFormat: AVCaptureDevice.Format? = nil,
        preferredCameraPosition: AVCaptureDevice.Position = .front
    ) {
        self.preferredFormat = preferredFormat
        self.preferredCameraPosition = preferredCameraPosition
    }

    func with(preferredCameraPosition: AVCaptureDevice.Position) -> VideoOptions {
        .init(
            preferredFormat: preferredFormat,
            preferredCameraPosition: preferredCameraPosition
        )
    }
}
