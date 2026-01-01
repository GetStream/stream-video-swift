//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// Defines the requirements for a WebRTC statistics adapter.
///
/// This protocol abstracts the interface for any component responsible for
/// collecting, reporting, and tracing WebRTC statistics in the SDK. It
/// supports configuration of SFU adapters, peer connections, reporting
/// intervals, and exposes publishers for the latest stats reports.
/// Conforming types must be `AnyObject` and `Sendable`.
protocol WebRTCStatsAdapting: AnyObject, Sendable {
    /// The SFU adapter used to send statistics and trace events.
    ///
    /// Setting this property re-attaches all observers and subscriptions to the
    /// new adapter instance.
    var sfuAdapter: SFUAdapter? { get set }

    /// The publisher peer connection coordinator.
    ///
    /// Setting this property re-attaches statistics and trace collection for the
    /// publisher peer connection.
    var publisher: RTCPeerConnectionCoordinator? { get set }

    /// The subscriber peer connection coordinator.
    ///
    /// Setting this property re-attaches statistics and trace collection for the
    /// subscriber peer connection.
    var subscriber: RTCPeerConnectionCoordinator? { get set }

    /// The interval (in seconds) at which statistics are reported.
    ///
    /// Changing this property reschedules the stats reporting timer.
    var deliveryInterval: TimeInterval { get set }

    /// Indicates whether trace collection and reporting are enabled.
    ///
    /// When disabled, trace buffering and reporting will be halted.
    var isTracingEnabled: Bool { get set }

    /// The number of reconnect attempts for this session.
    var reconnectAttempts: UInt32 { get set }

    /// A publisher that emits the latest WebRTC call statistics report.
    ///
    /// This publisher emits only non-nil reports as they are collected.
    var latestReportPublisher: AnyPublisher<CallStatsReport, Never> { get }

    /// The unique session identifier for statistics and trace reporting.
    var sessionID: String { get }

    /// An additional identifier for unified reporting.
    var unifiedSessionID: String { get }

    /// Triggers immediate stats reporting via the adapter's reporter.
    func scheduleStatsReporting()

    /// Forwards a trace event to the trace adapter for buffering.
    ///
    /// - Parameter trace: The trace event to record.
    func trace(_ trace: WebRTCTrace)

    func consume(_ bucket: ConsumableBucket<WebRTCTrace>)
}
