//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

/// Abstracts the stats collection interface.
protocol WebRTCStatsCollecting: AnyObject, Sendable {
    /// The most recent CallStatsReport generated from collected stats.
    var report: CallStatsReport? { get }

    /// Publisher for the most recent stats report.
    var reportPublisher: AnyPublisher<CallStatsReport?, Never> { get }

    /// The publisher peer connection.
    var publisher: RTCPeerConnectionCoordinator? { get set }

    /// The subscriber peer connection.
    var subscriber: RTCPeerConnectionCoordinator? { get set }

    /// The SFU adapter.
    var sfuAdapter: SFUAdapter? { get set }

    /// The collection interval, in seconds.
    var interval: TimeInterval { get set }
}
