//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import StreamWebRTC

final class MockWebRTCTracesAdapter: WebRTCTracing, Mockable, @unchecked Sendable {

    typealias FunctionKey = MockFunctionKey
    typealias FunctionInputKey = MockFunctionInputKey

    enum MockFunctionKey: Hashable, CaseIterable {
        case trace
        case flushTraces
        case flushEncoderPerformanceStats
        case flushDecoderPerformanceStats
        case restore
        case consume
    }

    enum MockFunctionInputKey: Payloadable {
        case trace(WebRTCTrace)
        case flushTraces
        case flushEncoderPerformanceStats
        case flushDecoderPerformanceStats
        case restore([WebRTCTrace])
        case consume(ConsumableBucket<WebRTCTrace>)

        var payload: Any {
            switch self {
            case let .trace(trace):
                return trace
            case .flushTraces:
                return ()
            case .flushEncoderPerformanceStats:
                return ()
            case .flushDecoderPerformanceStats:
                return ()
            case let .restore(traces):
                return traces
            case let .consume(bucket):
                return bucket
            }
        }
    }

    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [FunctionKey: Any] = [:]
    @Atomic var stubbedFunctionInput: [FunctionKey: [MockFunctionInputKey]] =
        MockFunctionKey.allCases.reduce(into: [:]) { $0[$1] = [] }

    // MARK: - Mockable helpers

    func stub<T>(for keyPath: KeyPath<MockWebRTCTracesAdapter, T>, with value: T) {
        stubbedProperty[propertyKey(for: keyPath)] = value
    }

    func stub<T>(for function: FunctionKey, with value: T) {
        stubbedFunction[function] = value
    }

    // MARK: - Public Properties

    var isEnabled: Bool {
        get { self[dynamicMember: \.isEnabled] }
        set { stub(for: \.isEnabled, with: newValue) }
    }

    var sfuAdapter: SFUAdapter? {
        get { self[dynamicMember: \.sfuAdapter] }
        set { stub(for: \.sfuAdapter, with: newValue) }
    }

    var publisher: RTCPeerConnectionCoordinator? {
        get { self[dynamicMember: \.publisher] }
        set { stub(for: \.publisher, with: newValue) }
    }

    var subscriber: RTCPeerConnectionCoordinator? {
        get { self[dynamicMember: \.subscriber] }
        set { stub(for: \.subscriber, with: newValue) }
    }

    // MARK: - Methods

    func trace(_ trace: WebRTCTrace) {
        stubbedFunctionInput[.trace]?.append(.trace(trace))
    }

    func flushTraces() -> [WebRTCTrace] {
        stubbedFunctionInput[.flushTraces]?.append(.flushTraces)
        return stubbedFunction[.flushTraces] as? [WebRTCTrace] ?? []
    }

    func flushEncoderPerformanceStats() -> [Stream_Video_Sfu_Models_PerformanceStats] {
        stubbedFunctionInput[.flushEncoderPerformanceStats]?.append(.flushEncoderPerformanceStats)
        return stubbedFunction[.flushEncoderPerformanceStats] as? [Stream_Video_Sfu_Models_PerformanceStats] ?? []
    }

    func flushDecoderPerformanceStats() -> [Stream_Video_Sfu_Models_PerformanceStats] {
        stubbedFunctionInput[.flushDecoderPerformanceStats]?.append(.flushDecoderPerformanceStats)
        return stubbedFunction[.flushDecoderPerformanceStats] as? [Stream_Video_Sfu_Models_PerformanceStats] ?? []
    }

    func restore(_ traces: [WebRTCTrace]) {
        stubbedFunctionInput[.restore]?.append(.restore(traces))
    }

    func consume(_ bucket: ConsumableBucket<WebRTCTrace>) {
        stubbedFunctionInput[.consume]?.append(.consume(bucket))
    }
}
