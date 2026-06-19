//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
@testable import StreamVideo

final class MockWebRTCStatsAdapter: Mockable, WebRTCStatsAdapting, @unchecked Sendable {

    // MARK: - Mockable

    typealias FunctionKey = MockFunctionKey
    typealias FunctionInputKey = MockFunctionInputKey

    enum MockFunctionKey: Hashable, CaseIterable {
        case scheduleStatsReporting
        case trace
        case consume
    }

    enum MockFunctionInputKey: Payloadable {
        case scheduleStatsReporting
        case trace(WebRTCTrace)
        case consume(ConsumableBucket<WebRTCTrace>)

        var payload: Any {
            switch self {
            case .scheduleStatsReporting:
                return ()
            case let .trace(trace):
                return trace
            case let .consume(bucket):
                return bucket
            }
        }
    }

    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [FunctionKey: Any] = [:]
    @Atomic var stubbedFunctionInput: [FunctionKey: [MockFunctionInputKey]] =
        MockFunctionKey.allCases.reduce(into: [:]) { $0[$1] = [] }

    func stub<T>(for keyPath: KeyPath<MockWebRTCStatsAdapter, T>, with value: T) {
        stubbedProperty[propertyKey(for: keyPath)] = value
    }

    func stub<T>(for function: FunctionKey, with value: T) {
        stubbedFunction[function] = value
    }

    init() {
        stub(for: \.deliveryInterval, with: 1)
        stub(for: \.isTracingEnabled, with: true)
        stub(for: \.reconnectAttempts, with: 0)
        stub(for: \.latestReportPublisher, with: latestReportSubject.eraseToAnyPublisher())
        stub(for: \.sessionID, with: String.unique)
        stub(for: \.unifiedSessionID, with: String.unique)
    }

    let latestReportSubject: PassthroughSubject<CallStatsReport, Never> = .init()

    // MARK: - WebRTCStatsAdapting

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

    var deliveryInterval: TimeInterval {
        get { self[dynamicMember: \.deliveryInterval] }
        set { stub(for: \.deliveryInterval, with: newValue) }
    }

    var isTracingEnabled: Bool {
        get { self[dynamicMember: \.isTracingEnabled] }
        set { stub(for: \.isTracingEnabled, with: newValue) }
    }

    var reconnectAttempts: UInt32 {
        get { self[dynamicMember: \.reconnectAttempts] }
        set { stub(for: \.reconnectAttempts, with: newValue) }
    }

    var latestReportPublisher: AnyPublisher<CallStatsReport, Never> {
        get { self[dynamicMember: \.latestReportPublisher] }
        set { stub(for: \.latestReportPublisher, with: newValue) }
    }

    var sessionID: String {
        get { self[dynamicMember: \.sessionID] }
        set { stub(for: \.sessionID, with: newValue) }
    }

    var unifiedSessionID: String {
        get { self[dynamicMember: \.unifiedSessionID] }
        set { stub(for: \.unifiedSessionID, with: newValue) }
    }

    func scheduleStatsReporting() {
        stubbedFunctionInput[.scheduleStatsReporting]?.append(.scheduleStatsReporting)
    }

    func trace(_ trace: WebRTCTrace) {
        stubbedFunctionInput[.trace]?.append(.trace(trace))
    }

    func consume(_ bucket: ConsumableBucket<WebRTCTrace>) {
        stubbedFunctionInput[.consume]?.append(.consume(bucket))
    }
}
