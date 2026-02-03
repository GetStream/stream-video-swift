//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreVideo
import Foundation
import StreamWebRTC

/// Rotation for frames pushed to an external frame sink. Maps to WebRTC rotation.
public enum ExternalVideoRotation: Sendable {
    case none
    case rotate90
    case rotate180
    case rotate270

    var rtcRotation: RTCVideoRotation {
        switch self {
        case .none: return ._0
        case .rotate90: return ._90
        case .rotate180: return ._180
        case .rotate270: return ._270
        }
    }
}

/// Protocol for pushing video frames from an external source (e.g. wearable camera) into the WebRTC pipeline.
/// When using a custom video capturer provider that uses an external source, the SDK delivers a frame sink
/// via the session-ready callback; the app pushes frames at the desired rate (e.g. ~30 fps).
public protocol ExternalFrameSink: Sendable {
    /// Pushes a single video frame. Call from your capture loop at the desired frame rate.
    /// - Parameters:
    ///   - pixelBuffer: The frame image (e.g. from wearable pipeline).
    ///   - rotation: Rotation of the frame (e.g. `.none` for no rotation).
    func pushFrame(pixelBuffer: CVPixelBuffer, rotation: ExternalVideoRotation)
}
