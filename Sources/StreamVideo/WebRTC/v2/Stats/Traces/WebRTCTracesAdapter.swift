//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC
import SwiftProtobuf

final class WebRTCTracesAdapter: @unchecked Sendable {

    private enum DisposableKey: String {
        case publisher
        case subscriber
        case changePublishQuality
        case callEnded
        case goAway
        case error
    }

    struct TraceMethodError<V: Encodable>: Encodable { var input: V; var error: String }

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
        didSet { didUpdate(callSettings) }
    }

    var audioSession: StreamAudioSession?

    private let peerConnectionBucket: ConsumableBucket<WebRTCTrace>
    private var sfuRequestsBucket: ConsumableBucket<WebRTCTrace>
    private let encoderStatsBucket: ConsumableBucket<[Stream_Video_Sfu_Models_PerformanceStats]>
    private let decoderStatsBucket: ConsumableBucket<[Stream_Video_Sfu_Models_PerformanceStats]>

    private let disposableBag = DisposableBag()

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

    func flushTraces() -> [WebRTCTrace] {
        let peerConnectionTraces = peerConnectionBucket.consume(flush: true)
        let sfuRequestsTraces = sfuRequestsBucket.consume(flush: true)
        return peerConnectionTraces + sfuRequestsTraces
    }

    func flushEncoderPerformanceStats() -> [Stream_Video_Sfu_Models_PerformanceStats] {
        encoderStatsBucket.consume(flush: true).flatMap { $0 }
    }

    func flushDecoderPerformanceStats() -> [Stream_Video_Sfu_Models_PerformanceStats] {
        decoderStatsBucket.consume(flush: true).flatMap { $0 }
    }

    // MARK: -

    func restore(_ traces: [WebRTCTrace]) {
        peerConnectionBucket.insert(traces, at: 0)
    }

    // MARK: - Private Helpers

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

    private func didUpdate(_ callSettings: CallSettings?) {
        guard let callSettings, let audioSession else {
            return
        }
        peerConnectionBucket.append(
            .init(callSettings: callSettings, audioSession: audioSession)
        )
    }
}
