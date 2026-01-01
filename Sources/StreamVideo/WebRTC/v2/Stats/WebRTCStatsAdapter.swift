//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

/// Collects, compresses, and reports WebRTC statistics and traces.
///
/// This adapter acts as a central manager for stats collection, delivery,
/// and trace event buffering. It coordinates between publisher/subscriber
/// peer connections, the SFU adapter, and the underlying audio session to
/// provide a unified reporting pipeline for WebRTC stats and performance.
/// Integrates with Combine for reactive reporting and supports trace state
/// restoration in the event of network errors or reconnects.
final class WebRTCStatsAdapter: @unchecked Sendable, WebRTCStatsAdapting {

    /// Identifiers for the different Combine subscriptions/disposables in use.
    private enum DisposableKey: String {
        case publisherUpdated
        case trackMuteStateUpdated
        case trackMuteStateObservation
    }

    /// The SFU adapter used to send collected statistics and trace events.
    ///
    /// Setting this property will re-attach all relevant observers and
    /// subscriptions to the new adapter instance.
    var sfuAdapter: SFUAdapter? { didSet { didUpdate(sfuAdapter) } }

    /// The publisher/subscriber peer connection coordinator.
    ///
    /// Setting this will re-attach statistics and trace collection to the
    /// updated connection instance.
    var publisher: RTCPeerConnectionCoordinator? {
        didSet { didUpdate(publisher: publisher) }
    }

    /// The publisher/subscriber peer connection coordinator.
    ///
    /// Setting this will re-attach statistics and trace collection to the
    /// updated connection instance.
    var subscriber: RTCPeerConnectionCoordinator? {
        didSet { didUpdate(subscriber: subscriber) }
    }

    /// The interval at which statistics are reported (in seconds).
    ///
    /// Changing this property reschedules the reporting timer.
    var deliveryInterval: TimeInterval {
        didSet { reporter.interval = deliveryInterval }
    }

    /// Whether trace collection and reporting is enabled for this adapter.
    ///
    /// When disabled, trace buffering and reporting will be halted.
    var isTracingEnabled: Bool {
        get { traces.isEnabled }
        set { traces.isEnabled = newValue }
    }

    /// The number of reconnect attempts for this session.
    var reconnectAttempts: UInt32

    /// A publisher that emits the latest WebRTC call stats report.
    ///
    /// This publisher emits only non-nil reports as they are collected.
    var latestReportPublisher: AnyPublisher<CallStatsReport, Never> {
        collector
            .reportPublisher
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    /// Session identifiers for stats and trace reporting.
    let sessionID: String

    /// Session identifiers for stats and trace reporting.
    let unifiedSessionID: String

    /// Storage for WebRTC tracks used by the stats collector.
    private let trackStorage: WebRTCTrackStorage
    /// Manages Combine subscriptions for all observation and reporting.
    private let disposableBag = DisposableBag()

    /// The interval at which raw statistics are collected (in seconds).
    ///
    /// Changing this will update the collector's internal timer.
    private var collectionInterval: TimeInterval {
        didSet { collector.interval = collectionInterval }
    }

    /// The collector responsible for periodic collection of WebRTC stats.
    private lazy var collector: WebRTCStatsCollecting = WebRTCStatsCollector(
        interval: collectionInterval,
        trackStorage: trackStorage
    )

    /// The reporter responsible for periodic delivery of compressed stats
    /// and trace events.
    private lazy var reporter: WebRTCStatsReporting = WebRTCStatsReporter(
        interval: deliveryInterval,
        provider: { [weak self] in self?.prepareDeliveryInput() }
    )
    /// Adapter responsible for buffering and restoring WebRTC trace events.
    private lazy var traces: WebRTCTracing = WebRTCTracesAdapter(latestReportPublisher: latestReportPublisher)
    /// Compresses raw stats reports for efficient reporting.
    private lazy var statsCompressor = WebRTCStatsCompressor()

    convenience init(
        collectionInterval: TimeInterval = 2,
        deliveryInterval: TimeInterval = 5,
        sessionID: String,
        unifiedSessionID: String,
        isTracingEnabled: Bool,
        reconnectAttempts: UInt32 = 0,
        trackStorage: WebRTCTrackStorage,
        collector: WebRTCStatsCollecting,
        reporter: WebRTCStatsReporting,
        traces: WebRTCTracing
    ) {
        self.init(
            collectionInterval: collectionInterval,
            deliveryInterval: deliveryInterval,
            sessionID: sessionID,
            unifiedSessionID: unifiedSessionID,
            isTracingEnabled: isTracingEnabled,
            reconnectAttempts: reconnectAttempts,
            trackStorage: trackStorage
        )

        self.collector = collector
        self.reporter = reporter
        self.traces = traces
    }

    /// Initializes a new WebRTCStatsAdapter.
    ///
    /// - Parameters:
    ///   - collectionInterval: Stats collection interval (seconds).
    ///   - deliveryInterval: Stats reporting interval (seconds).
    ///   - sessionID: The current session's identifier.
    ///   - unifiedSessionID: An additional identifier for unified reporting.
    ///   - isTracingEnabled: Whether traces should be enabled.
    ///   - reconnectAttempts: Number of reconnects for this session.
    ///   - trackStorage: The track storage used for stats collection.
    init(
        collectionInterval: TimeInterval = 2,
        deliveryInterval: TimeInterval = 5,
        sessionID: String,
        unifiedSessionID: String,
        isTracingEnabled: Bool,
        reconnectAttempts: UInt32 = 0,
        trackStorage: WebRTCTrackStorage
    ) {
        self.sessionID = sessionID
        self.unifiedSessionID = unifiedSessionID
        self.reconnectAttempts = reconnectAttempts
        self.collectionInterval = collectionInterval
        self.deliveryInterval = deliveryInterval
        self.trackStorage = trackStorage
        self.isTracingEnabled = isTracingEnabled

        _ = collector
        _ = reporter
        _ = traces

        traces.isEnabled = isTracingEnabled
    }

    // MARK: - Stats

    /// Triggers immediate stats reporting via the reporter.
    func scheduleStatsReporting() {
        reporter.triggerDelivery()
    }

    // MARK: - Traces

    /// Forwards a trace event to the trace adapter for buffering.
    ///
    /// - Parameter trace: The trace event to record.
    func trace(_ trace: WebRTCTrace) {
        traces.trace(trace)
    }

    func consume(_ bucket: ConsumableBucket<WebRTCTrace>) {
        traces.consume(bucket)
    }

    // MARK: - Private helpers

    /// Handles updates to the SFU adapter, reattaching all relevant observers.
    ///
    /// - Parameter sfuAdapter: The new SFU adapter instance.
    private func didUpdate(_ sfuAdapter: SFUAdapter?) {
        collector.sfuAdapter = sfuAdapter
        reporter.sfuAdapter = sfuAdapter
        traces.sfuAdapter = sfuAdapter
        observeTracksMuteStateChanges(sfuAdapter)
    }

    /// Handles updates to publisher/subscriber peer connections.
    ///
    /// Reattaches stats and trace collection to the new connection, if present.
    ///
    /// - Parameter publisher/subscriber: The new peer connection instance.
    private func didUpdate(publisher: RTCPeerConnectionCoordinator?) {
        collector.publisher = publisher
        traces.publisher = publisher

        if publisher != nil {
            scheduleStatsReporting(for: .publisherUpdated)
        } else {
            disposableBag.remove(DisposableKey.publisherUpdated.rawValue)
        }
    }

    /// Handles updates to publisher/subscriber peer connections.
    ///
    /// Reattaches stats and trace collection to the new connection, if present.
    ///
    /// - Parameter publisher/subscriber: The new peer connection instance.
    private func didUpdate(subscriber: RTCPeerConnectionCoordinator?) {
        collector.subscriber = subscriber
        traces.subscriber = subscriber
    }

    /// Prepares the delivery input for the reporter, flushing traces and
    /// compressing stats.
    ///
    /// - Returns: An optional input for the reporter's delivery event.
    private func prepareDeliveryInput() -> WebRTCStatsReporter.Input? {
        guard let report = collector.report else {
            return nil
        }

        let compressedReport = statsCompressor.compress(report)

        if let stats = compressedReport.publisher {
            traces.trace(.init(peerType: .publisher, statsReport: stats))
        }
        if let stats = compressedReport.subscriber {
            traces.trace(.init(peerType: .subscriber, statsReport: stats))
        }

        let reconnectAttempts = self.reconnectAttempts + 1
        let peerConnectionTraces = traces
            .flushTraces()
            .map {
                guard
                    let id = $0.id
                else {
                    return $0
                }
                var value = $0
                if id == PeerConnectionType.publisher.rawValue {
                    value.id = "\(reconnectAttempts)-pub"
                } else if id == PeerConnectionType.subscriber.rawValue {
                    value.id = "\(reconnectAttempts)-sub"
                } else if id == "sfu" {
                    value.id = "\(reconnectAttempts)-sfu"
                }
                return value
            }

        log.debug(
            "PeerConnection traces flushed: \(peerConnectionTraces.map { $0.id != nil ? "\($0.id):\($0.tag):\($0.timestamp)" : "\($0.tag):\($0.timestamp)" })",
            subsystems: .webRTC
        )

        return .init(
            sessionID: sessionID,
            unifiedSessionID: unifiedSessionID,
            report: report,
            peerConnectionTraces: peerConnectionTraces,
            encoderPerformanceStats: traces.flushEncoderPerformanceStats(),
            decoderPerformanceStats: traces.flushDecoderPerformanceStats(),
            onError: { [weak self] _ in self?.traces.restore(peerConnectionTraces) }
        )
    }

    /// Schedules periodic stats reporting for a given Combine subscription key.
    ///
    /// - Parameter key: The disposable key to manage the reporting timer.
    private func scheduleStatsReporting(for key: DisposableKey) {
        disposableBag.remove(key.rawValue)
        DefaultTimer
            .publish(every: 3)
            .sink { [weak self] _ in
                self?.reporter.triggerDelivery()
                self?.disposableBag.remove(key.rawValue)
            }
            .store(in: disposableBag, key: key.rawValue)
    }

    /// Observes mute state changes for SFU adapter tracks and triggers stats
    /// reporting when necessary.
    ///
    /// - Parameter sfuAdapter: The SFU adapter to observe.
    private func observeTracksMuteStateChanges(_ sfuAdapter: SFUAdapter?) {
        disposableBag.remove(DisposableKey.trackMuteStateObservation.rawValue)
        guard let sfuAdapter else {
            return
        }
        sfuAdapter
            .publisherSendEvent
            .filter { ($0 as? SFUAdapter.UpdateTrackMuteStateEvent)?.payload.muteStates.first { $0.trackType == .video } != nil }
            .sink { [weak self] _ in self?.scheduleStatsReporting(for: .trackMuteStateUpdated) }
            .store(in: disposableBag, key: DisposableKey.trackMuteStateObservation.rawValue)
    }
}
