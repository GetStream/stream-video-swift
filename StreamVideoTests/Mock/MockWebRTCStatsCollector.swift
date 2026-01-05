//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamVideo
import StreamWebRTC

final class MockWebRTCStatsCollector: WebRTCStatsCollecting, Mockable, @unchecked Sendable {

    typealias FunctionKey = MockFunctionKey
    typealias FunctionInputKey = EmptyPayloadable

    enum MockFunctionKey: Hashable, CaseIterable {}

    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [FunctionKey: Any] = [:]
    @Atomic var stubbedFunctionInput: [FunctionKey: [FunctionInputKey]] = [:]

    func stub<T>(for keyPath: KeyPath<MockWebRTCStatsCollector, T>, with value: T) {
        stubbedProperty[propertyKey(for: keyPath)] = value
    }

    func stub<T>(for function: FunctionKey, with value: T) {
        /* No-op */
    }

    // MARK: - Public Properties

    private var _report: CallStatsReport?
    var report: CallStatsReport? {
        get { _report }
        set { _report = newValue }
    }

    let reportSubject = PassthroughSubject<CallStatsReport?, Never>()
    var reportPublisher: AnyPublisher<CallStatsReport?, Never> {
        reportSubject.eraseToAnyPublisher()
    }

    var publisher: RTCPeerConnectionCoordinator? {
        get { self[dynamicMember: \.publisher] }
        set { stub(for: \.publisher, with: newValue) }
    }

    var subscriber: RTCPeerConnectionCoordinator? {
        get { self[dynamicMember: \.subscriber] }
        set { stub(for: \.subscriber, with: newValue) }
    }

    var sfuAdapter: SFUAdapter? {
        get { self[dynamicMember: \.sfuAdapter] }
        set { stub(for: \.sfuAdapter, with: newValue) }
    }

    var interval: TimeInterval {
        get { self[dynamicMember: \.interval] }
        set { stub(for: \.interval, with: newValue) }
    }
}
