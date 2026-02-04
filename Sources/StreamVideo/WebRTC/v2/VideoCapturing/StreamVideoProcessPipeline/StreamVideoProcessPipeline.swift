//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// Chains processing nodes before forwarding frames to the original capturer.
final class StreamVideoProcessPipeline: NSObject, RTCVideoCapturerDelegate {

    private let source: RTCVideoCapturerDelegate
    private let nodes: [StreamVideoProcessNode]

    /// Creates a pipeline that forwards processed frames to the provided source.
    /// - Parameters:
    ///   - source: The downstream delegate that receives processed frames.
    ///   - nodes: Ordered processing nodes to apply to each frame.
    init(
        source: RTCVideoCapturerDelegate,
        nodes: [StreamVideoProcessNode]
    ) {
        self.source = source
        self.nodes = nodes
        super.init()
    }

    /// Broadcasts a filter update to all pipeline nodes.
    /// - Parameter videoFilter: The filter to apply, or `nil` to disable filtering.
    func didUpdate(_ videoFilter: VideoFilter?) {
        nodes.forEach { $0.didUpdate(videoFilter) }
    }

    // MARK: - RTCVideoCapturerDelegate

    /// Applies pipeline nodes to a captured frame before forwarding it.
    /// - Parameters:
    ///   - capturer: The WebRTC capturer providing the frame.
    ///   - frame: The captured frame to process.
    func capturer(
        _ capturer: RTCVideoCapturer,
        didCapture frame: RTCVideoFrame
    ) {
        if nodes.isEmpty {
            source.capturer(capturer, didCapture: frame)
        } else {
            source.capturer(
                capturer,
                didCapture: nodes.reduce(frame) { $1.didCapture($0) }
            )
        }
    }
}
