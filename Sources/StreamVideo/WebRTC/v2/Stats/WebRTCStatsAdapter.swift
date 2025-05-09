//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

final class WebRTCStatsAdapter: @unchecked Sendable {

    private enum DisposableKey: String {
        case publisherUpdated
        case trackMuteStateUpdated
        case trackMuteStateObservation
    }

    /// The SFU adapter used to send collected statistics.
    ///
    /// Setting this property triggers a reset of the collection and delivery processes.
    var sfuAdapter: SFUAdapter? { didSet { didUpdate(sfuAdapter) } }

    /// The publisher peer connection from which to collect statistics.
    var publisher: RTCPeerConnectionCoordinator? {
        didSet { didUpdate(publisher: publisher) }
    }

    /// The subscriber peer connection from which to collect statistics.
    var subscriber: RTCPeerConnectionCoordinator? {
        didSet { didUpdate(subscriber: subscriber) }
    }

    var callSettings: CallSettings? {
        didSet { traces.callSettings = callSettings }
    }

    var audioSession: StreamAudioSession? {
        didSet { traces.audioSession = audioSession }
    }

    /// The interval at which statistics are reported, in seconds.
    ///
    /// Setting this property automatically reschedules the delivery timer.
    var deliveryInterval: TimeInterval {
        didSet { reporter.interval = deliveryInterval }
    }

    var isTracingEnabled: Bool {
        get { traces.isEnabled }
        set { traces.isEnabled = newValue }
    }

    var reconnectAttempts: UInt32

    /// A publisher for the latest statistics report.
    var latestReportPublisher: AnyPublisher<CallStatsReport, Never> {
        collector
            .$report
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    /// The session ID associated with this reporter.
    let sessionID: String

    let unifiedSessionID: String

    private let trackStorage: WebRTCTrackStorage
    private let disposableBag = DisposableBag()

    /// The interval at which statistics are collected, in seconds. Defaults to 2.
    private var collectionInterval: TimeInterval {
        didSet { collector.interval = collectionInterval }
    }

    private lazy var collector: WebRTCStatsCollector = .init(
        interval: collectionInterval,
        trackStorage: trackStorage
    )

    private lazy var reporter: WebRTCStatsReporter = .init(
        interval: deliveryInterval,
        provider: { [weak self] in self?.prepareDeliveryInput() }
    )
    private lazy var traces: WebRTCTracesAdapter = .init(latestReportPublisher: latestReportPublisher)
    private lazy var statsCompressor = WebRTCStatsCompressor()

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

    func scheduleStatsReporting() {
        reporter.triggerDelivery()
    }

    // MARK: - Traces

    func trace(_ trace: WebRTCTrace) {
        traces.trace(trace)
    }

    // MARK: - Private helpers

    private func didUpdate(_ sfuAdapter: SFUAdapter?) {
        collector.sfuAdapter = sfuAdapter
        reporter.sfuAdapter = sfuAdapter
        traces.sfuAdapter = sfuAdapter
        observeTracksMuteStateChanges(sfuAdapter)
    }

    private func didUpdate(publisher: RTCPeerConnectionCoordinator?) {
        collector.publisher = publisher
        traces.publisher = publisher

        if publisher != nil {
            scheduleStatsReporting(for: .publisherUpdated)
        } else {
            disposableBag.remove(DisposableKey.publisherUpdated.rawValue)
        }
    }

    private func didUpdate(subscriber: RTCPeerConnectionCoordinator?) {
        collector.subscriber = subscriber
        traces.subscriber = subscriber
    }

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

        let reconnectAttempts = self.reconnectAttempts
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

    private func scheduleStatsReporting(for key: DisposableKey) {
        disposableBag.remove(key.rawValue)
        Foundation
            .Timer
            .publish(every: 3, on: .main, in: .default)
            .autoconnect()
            .sink { [weak self] _ in
                self?.reporter.triggerDelivery()
                self?.disposableBag.remove(key.rawValue)
            }
            .store(in: disposableBag, key: key.rawValue)
    }

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
