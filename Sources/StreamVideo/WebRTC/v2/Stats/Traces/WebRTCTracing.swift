//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// Abstracts the trace collection and stats buffering interface for WebRTC.
///
/// Conforming types should support enabling/disabling, trace/event buffering,
/// and stats flushing/restoration.
protocol WebRTCTracing: AnyObject, Sendable {
    /// Enables or disables trace collection and buffering.
    var isEnabled: Bool { get set }

    /// The SFU adapter used for event/statistics.
    var sfuAdapter: SFUAdapter? { get set }

    /// Publisher peer connection coordinator.
    var publisher: RTCPeerConnectionCoordinator? { get set }

    /// Subscriber peer connection coordinator.
    var subscriber: RTCPeerConnectionCoordinator? { get set }

    /// Adds a trace event to the appropriate bucket.
    func trace(_ trace: WebRTCTrace)

    /// Immediately flushes and returns all buffered trace events.
    func flushTraces() -> [WebRTCTrace]

    /// Flushes and returns all buffered encoder performance stats.
    func flushEncoderPerformanceStats() -> [Stream_Video_Sfu_Models_PerformanceStats]

    /// Flushes and returns all buffered decoder performance stats.
    func flushDecoderPerformanceStats() -> [Stream_Video_Sfu_Models_PerformanceStats]

    /// Restores peer connection traces, inserting them at the front of the buffer.
    func restore(_ traces: [WebRTCTrace])

    func consume(_ bucket: ConsumableBucket<WebRTCTrace>)
}
