//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC
import SwiftProtobuf

/// Collects and manages WebRTC trace events and performance statistics.
///
/// This adapter organizes trace events and statistics from multiple sources,
/// such as publisher/subscriber peer connections and the SFU adapter.
/// It buffers traces and stats, provides mechanisms for flushing/consuming,
/// and can restore state. Integrates tightly with Combine pipelines and
/// automatically updates trace handling when associated connections or
/// adapters change.
///
/// - Note: Setting `isEnabled` to false will flush and clear all current buckets.
final class WebRTCTracesAdapter: WebRTCTracing, @unchecked Sendable {

    /// Identifiers for different disposable subscriptions in the adapter.
    private enum DisposableKey: String {
        case publisher
        case subscriber
        case changePublishQuality
        case callEnded
        case goAway
        case error
        case applicationState
        case thermalState
        case batteryLevel
        case batteryState
    }

    /// Used to wrap an error that occurred while tracing a method call, preserving
    /// the input that triggered the error for later debugging or reporting.
    struct TraceMethodError<V: Encodable>: Encodable { var input: V; var error: String }

    @Injected(\.applicationStateAdapter) private var applicationStateAdapter
    @Injected(\.thermalStateObserver) private var thermalStateObserver
    @Injected(\.currentDevice) private var currentDevice

    /// Enables or disables trace collection and statistics buffering.
    ///
    /// Setting this property to `false` will immediately flush and clear all
    /// buckets for peer connections, SFU requests, and performance statistics.
    var isEnabled: Bool = true {
        didSet {
            if !isEnabled {
                _ = peerConnectionBucket.consume(flush: true)
                _ = sfuRequestsBucket.consume(flush: true)
                _ = genericRequestsBucket.consume(flush: true)
                _ = encoderStatsBucket.consume(flush: true)
                _ = decoderStatsBucket.consume(flush: true)

                disposableBag.remove(DisposableKey.applicationState.rawValue)
                disposableBag.remove(DisposableKey.thermalState.rawValue)
                disposableBag.remove(DisposableKey.batteryLevel.rawValue)
                disposableBag.remove(DisposableKey.batteryState.rawValue)
            }
        }
    }

    /// The SFU adapter used to send and receive events/statistics.
    ///
    /// Updating this property will reset trace and stats collection, flush previous
    /// data, and re-attach Combine publishers to new event streams.
    var sfuAdapter: SFUAdapter? { didSet { didUpdate(sfuAdapter) } }

    /// The peer connection coordinator for the publisher/subscriber stream.
    ///
    /// Updating these will reset trace event collection for the respective role,
    /// flush prior traces, and attach to the new event stream.
    var publisher: RTCPeerConnectionCoordinator? {
        didSet { didUpdate(publisher: publisher) }
    }

    /// The peer connection coordinator for the publisher/subscriber stream.
    ///
    /// Updating these will reset trace event collection for the respective role,
    /// flush prior traces, and attach to the new event stream.
    var subscriber: RTCPeerConnectionCoordinator? {
        didSet { didUpdate(subscriber: subscriber) }
    }

    /// Buffers trace events related to publisher/subscriber peer connections.
    private let peerConnectionBucket: ConsumableBucket<WebRTCTrace>
    /// Buffers trace events related to SFU adapter requests and responses.
    private var sfuRequestsBucket: ConsumableBucket<WebRTCTrace>

    private var genericRequestsBucket: ConsumableBucket<WebRTCTrace>
    /// Buffers performance statistics for WebRTC encoding streams.
    private let encoderStatsBucket: ConsumableBucket<[Stream_Video_Sfu_Models_PerformanceStats]>
    /// Buffers performance statistics for WebRTC decoding streams.
    private let decoderStatsBucket: ConsumableBucket<[Stream_Video_Sfu_Models_PerformanceStats]>

    /// Manages Combine subscriptions for event publishers, keyed by role.
    private let disposableBag = DisposableBag()

    /// Creates a new traces adapter, wiring in Combine pipelines for performance stats.
    ///
    /// - Parameter latestReportPublisher: A publisher of the most recent call stats,
    ///   used to update encoder/decoder stats buckets in real-time.
    init(
        latestReportPublisher: AnyPublisher<CallStatsReport, Never>
    ) {
        peerConnectionBucket = .init()
        sfuRequestsBucket = .init()
        genericRequestsBucket = .init()

        encoderStatsBucket = .init(
            latestReportPublisher
                .compactMap {
                    guard
                        let stats = $0.publisherRawStats?.mutable
                    else { return nil }
                    return (stats: stats, trackToKindMap: $0.trackToKindMap)
                }
                .eraseToAnyPublisher(),
            transformer: WebRTCStatsItemTransformer(mode: .encoder)
        )

        decoderStatsBucket = .init(
            latestReportPublisher
                .compactMap {
                    guard
                        let stats = $0.subscriberRawStats?.mutable
                    else { return nil }
                    return (stats: stats, trackToKindMap: $0.trackToKindMap)
                }
                .eraseToAnyPublisher(),
            transformer: WebRTCStatsItemTransformer(mode: .decoder)
        )

        applicationStateAdapter
            .statePublisher
            .map { WebRTCTrace(applicationState: $0) }
            .sink { [weak self] in self?.trace($0) }
            .store(in: disposableBag, key: DisposableKey.applicationState.rawValue)

        thermalStateObserver
            .statePublisher
            .map { WebRTCTrace(thermalState: $0) }
            .sink { [weak self] in self?.trace($0) }
            .store(in: disposableBag, key: DisposableKey.thermalState.rawValue)
    }

    /// Appends a trace event to the appropriate bucket.
    ///
    /// Peer connection events are routed to the peer connection bucket, while SFU
    /// request/response events are routed to the SFU bucket.
    ///
    /// - Parameter trace: The WebRTC trace event to buffer.
    func trace(_ trace: WebRTCTrace) {
        guard isEnabled else {
            return
        }
        if let traceId = trace.id {
            if traceId == "sfu" {
                sfuRequestsBucket.append(trace)
            } else {
                peerConnectionBucket.append(trace)
            }
        } else {
            genericRequestsBucket.append(trace)
        }
    }

    // MARK: - Flush

    /// Immediately flushes and returns all collected trace events.
    ///
    /// Empties both peer connection and SFU trace buckets and returns all events.
    ///
    /// - Returns: All trace events in both peer connection and SFU buckets.
    func flushTraces() -> [WebRTCTrace] {
        let peerConnectionTraces = peerConnectionBucket.consume(flush: true)
        let sfuRequestsTraces = sfuRequestsBucket.consume(flush: true)
        let genericRequestsTraces = genericRequestsBucket.consume(flush: true)
        return peerConnectionTraces + sfuRequestsTraces + genericRequestsTraces
    }

    /// Flushes all buffered WebRTC encoder performance statistics.
    ///
    /// - Returns: All encoder stats buffered since last flush.
    func flushEncoderPerformanceStats() -> [Stream_Video_Sfu_Models_PerformanceStats] {
        encoderStatsBucket.consume(flush: true).flatMap { $0 }
    }

    /// Flushes all buffered WebRTC decoder performance statistics.
    ///
    /// - Returns: All decoder stats buffered since last flush.
    func flushDecoderPerformanceStats() -> [Stream_Video_Sfu_Models_PerformanceStats] {
        decoderStatsBucket.consume(flush: true).flatMap { $0 }
    }

    // MARK: -

    /// Restores peer connection traces from a given list, inserting them at the front.
    ///
    /// - Parameter traces: The traces to restore.
    func restore(_ traces: [WebRTCTrace]) {
        var sfuTraces = [WebRTCTrace]()
        var genericTraces = [WebRTCTrace]()
        var peerConnection = [WebRTCTrace]()
        traces.forEach { trace in
            guard let id = trace.id else {
                genericTraces.append(trace)
                return
            }

            if id.hasSuffix("sfu") {
                sfuTraces.append(trace)
            } else {
                peerConnection.append(trace)
            }
        }

        sfuRequestsBucket.insert(sfuTraces, at: 0)
        genericRequestsBucket.insert(genericTraces, at: 0)
        peerConnectionBucket.insert(peerConnection, at: 0)
    }

    func consume(_ bucket: ConsumableBucket<WebRTCTrace>) {
        let traces = bucket.consume(flush: true)
        traces.forEach { trace($0) }
    }

    // MARK: - Private Helpers

    /// Handles changes to the SFU adapter instance.
    ///
    /// Attaches new Combine subscriptions to event streams, flushes previous buckets,
    /// and emits an SFU "created" event as the first trace for the new adapter.
    private func didUpdate(_ sfuAdapter: SFUAdapter?) {
        guard let sfuAdapter else {
            return
        }

        // We collect the pending items from the current SFU (if any). We will
        // apply them in the new bucket once it has been created.
        let pendingSFUItems = sfuRequestsBucket.consume(flush: true)
        sfuRequestsBucket = .init(
            sfuAdapter
                .publisherSendEvent
                .map { WebRTCTrace(event: $0) }
                .eraseToAnyPublisher()
        )
        sfuRequestsBucket.insert(pendingSFUItems, at: 0)

        sfuRequestsBucket
            .append(.init(event: SFUAdapter.CreateEvent(hostname: sfuAdapter.host)))

        sfuAdapter
            .publisher(eventType: Stream_Video_Sfu_Event_CallEnded.self)
            .sink { [weak self] in self?.sfuRequestsBucket.append(.init(tag: "callEnded", event: $0)) }
            .store(in: disposableBag, key: DisposableKey.callEnded.rawValue)

        sfuAdapter
            .publisher(eventType: Stream_Video_Sfu_Event_ChangePublishQuality.self)
            .sink { [weak self] in self?.sfuRequestsBucket.append(.init(tag: "changePublishQuality", event: $0)) }
            .store(in: disposableBag, key: DisposableKey.changePublishQuality.rawValue)

        sfuAdapter
            .publisher(eventType: Stream_Video_Sfu_Event_GoAway.self)
            .sink { [weak self] in self?.sfuRequestsBucket.append(.init(tag: "goAway", event: $0)) }
            .store(in: disposableBag, key: DisposableKey.goAway.rawValue)

        sfuAdapter
            .publisher(eventType: Stream_Video_Sfu_Event_Error.self)
            .sink { [weak self] in self?.sfuRequestsBucket.append(.init(tag: "error", event: $0)) }
            .store(in: disposableBag, key: DisposableKey.error.rawValue)
    }

    /// Handles changes to the publisher/subscriber peer connection.
    ///
    /// Sets up Combine event pipeline for trace collection for the specified role,
    /// emits a "Created" event for the new peer connection, and clears prior traces.
    private func didUpdate(publisher: RTCPeerConnectionCoordinator?) {
        guard let peerConnection = publisher else {
            return
        }
        disposableBag.remove(DisposableKey.publisher.rawValue)
        peerConnection
            .eventPublisher
            .filter { [weak self] _ in self?.isEnabled == true }
            .map { WebRTCTrace(peerType: .publisher, event: $0) }
            .log(.debug, subsystems: .webRTC) { "Trace tag:\($0.tag) create for id:\($0.id) at timestamp:\($0.timestamp)." }
            .sink { [weak self] in self?.peerConnectionBucket.append($0) }
            .store(in: disposableBag, key: DisposableKey.publisher.rawValue)

        peerConnectionBucket.append(
            .init(
                peerType: .publisher,
                event: StreamRTCPeerConnection.CreatedEvent(
                    configuration: peerConnection.configuration,
                    hostname: sfuAdapter?.host ?? ""
                )
            )
        )
    }

    /// Handles changes to the publisher/subscriber peer connection.
    ///
    /// Sets up Combine event pipeline for trace collection for the specified role,
    /// emits a "Created" event for the new peer connection, and clears prior traces.
    private func didUpdate(subscriber: RTCPeerConnectionCoordinator?) {
        guard let peerConnection = subscriber else {
            return
        }
        disposableBag.remove(DisposableKey.subscriber.rawValue)
        peerConnection
            .eventPublisher
            .filter { [weak self] _ in self?.isEnabled == true }
            .map { WebRTCTrace(peerType: .subscriber, event: $0) }
            .log(.debug, subsystems: .webRTC) { "Trace tag:\($0.tag) create for id:\($0.id) at timestamp:\($0.timestamp)." }
            .sink { [weak self] in self?.peerConnectionBucket.append($0) }
            .store(in: disposableBag, key: DisposableKey.subscriber.rawValue)

        peerConnectionBucket.append(
            .init(
                peerType: .subscriber,
                event: StreamRTCPeerConnection.CreatedEvent(
                    configuration: peerConnection.configuration,
                    hostname: sfuAdapter?.host ?? ""
                )
            )
        )
    }
}
