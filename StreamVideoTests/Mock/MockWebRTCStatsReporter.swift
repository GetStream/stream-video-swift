//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import StreamWebRTC

final class MockWebRTCStatsReporter: WebRTCStatsReporting, Mockable, @unchecked Sendable {

    typealias FunctionKey = MockFunctionKey
    typealias FunctionInputKey = MockFunctionInputKey

    enum MockFunctionKey: Hashable, CaseIterable {
        case triggerDelivery
    }

    enum MockFunctionInputKey: Payloadable {
        case triggerDelivery

        var payload: Any {
            switch self {
            case .triggerDelivery: return ()
            }
        }
    }

    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [FunctionKey: Any] = [:]
    @Atomic var stubbedFunctionInput: [FunctionKey: [MockFunctionInputKey]] =
        MockFunctionKey.allCases.reduce(into: [:]) { $0[$1] = [] }

    func stub<T>(for keyPath: KeyPath<MockWebRTCStatsReporter, T>, with value: T) {
        stubbedProperty[propertyKey(for: keyPath)] = value
    }

    func stub<T>(for function: FunctionKey, with value: T) {
        stubbedFunction[function] = value
    }

    // MARK: - Public Properties

    var interval: TimeInterval {
        get { self[dynamicMember: \.interval] }
        set { stub(for: \.interval, with: newValue) }
    }

    var sfuAdapter: SFUAdapter? {
        get { self[dynamicMember: \.sfuAdapter] }
        set { stub(for: \.sfuAdapter, with: newValue) }
    }

    // MARK: - Methods

    func triggerDelivery() {
        stubbedFunctionInput[.triggerDelivery]?.append(.triggerDelivery)
    }
}
