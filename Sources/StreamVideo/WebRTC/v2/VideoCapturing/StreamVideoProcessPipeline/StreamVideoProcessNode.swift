//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// Defines a pipeline stage that can mutate or pass through captured frames.
protocol StreamVideoProcessNode {

    /// Updates the node with the active video filter.
    /// - Parameter videoFilter: The filter to apply, or `nil` to disable filtering.
    func didUpdate(_ videoFilter: VideoFilter?)

    /// Processes a captured frame and returns the frame to forward downstream.
    /// - Parameter frame: The frame to process.
    /// - Returns: The frame to pass to the next node.
    func didCapture(_ frame: RTCVideoFrame) -> RTCVideoFrame
}
