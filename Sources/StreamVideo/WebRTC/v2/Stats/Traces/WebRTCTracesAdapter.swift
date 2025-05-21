//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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
    }

    /// Used to wrap an error that occurred while tracing a method call, preserving
    /// the input that triggered the error for later debugging or reporting.
    struct TraceMethodError<V: Encodable>: Encodable { var input: V; var error: String }

    /// Enables or disables trace collection and statistics buffering.
    ///
    /// Setting this property to `false` will immediately flush and clear all
    /// buckets for peer connections, SFU requests, and performance statistics.
    var isEnabled: Bool = true {
        didSet {
            if !isEnabled {
                _ = peerConnectionBucket.consume(flush: true)
                _ = sfuRequestsBucket.consume(flush: true)
                _ = encoderStatsBucket.consume(flush: true)
                _ = decoderStatsBucket.consume(flush: true)
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

    /// Current call settings for the ongoing session. Updating this triggers a
    /// trace update for session-related state.
    var callSettings: CallSettings? {
        didSet { didUpdate(callSettings) }
    }

    /// Audio session in use for this call. Used to enrich trace data with audio state.
    var audioSession: StreamAudioSession?

    /// Buffers trace events related to publisher/subscriber peer connections.
    private let peerConnectionBucket: ConsumableBucket<WebRTCTrace>
    /// Buffers trace events related to SFU adapter requests and responses.
    private var sfuRequestsBucket: ConsumableBucket<WebRTCTrace>
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

        encoderStatsBucket = .init(
            latestReportPublisher,
            transformer: WebRTCEncoderStatsItemTransformer()
        )

        decoderStatsBucket = .init(
            latestReportPublisher,
            transformer: WebRTCDecoderStatsItemTransformer()
        )
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
        if trace.id != nil {
            peerConnectionBucket.append(trace)
        } else {
            sfuRequestsBucket.append(trace)
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
        return peerConnectionTraces + sfuRequestsTraces
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
        peerConnectionBucket.insert(traces, at: 0)
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
        // TODO: Ensure we have flushed the bucket before this operation.
        sfuRequestsBucket = .init(
            sfuAdapter
                .publisherSendEvent
                .map { WebRTCTrace(event: $0) }
                .eraseToAnyPublisher()
        )

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

    /// Handles updates to call settings and audio session state.
    ///
    /// Enriches trace data with the latest call and audio configuration.
    private func didUpdate(_ callSettings: CallSettings?) {
        guard let callSettings, let audioSession else {
            return
        }
        peerConnectionBucket.append(
            .init(callSettings: callSettings, audioSession: audioSession)
        )
    }
}
