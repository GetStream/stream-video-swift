//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// Configuration for the video options for a call.
///
/// This structure defines settings related to video configuration during a call.
/// It allows specifying preferences such as the default camera position.
struct VideoOptions: Sendable {

    /// The preferred camera position for video capture.
    ///
    /// This property determines which camera (e.g., front or back) should be
    /// used as the default for video capture during a call.
    var preferredCameraPosition: AVCaptureDevice.Position

    /// Creates a new instance of `VideoOptions` with the specified configuration.
    ///
    /// - Parameter preferredCameraPosition: The preferred camera position for
    ///   video capture. Defaults to `.front`.
    init(
        preferredCameraPosition: AVCaptureDevice.Position = .front
    ) {
        self.preferredCameraPosition = preferredCameraPosition
    }
}
