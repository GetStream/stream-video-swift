//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo

final class MockThermalStateObserver: ThermalStateObserving, Mockable, @unchecked Sendable {

    // MARK: - Mockable

    typealias FunctionKey = MockFunctionKey
    typealias FunctionInputKey = EmptyPayloadable
    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [FunctionKey: Any] = [:]
    @Atomic var stubbedFunctionInput: [FunctionKey: [FunctionInputKey]] = [:]
    func stub<T>(for keyPath: KeyPath<MockThermalStateObserver, T>, with value: T) {
        stubbedProperty[propertyKey(for: keyPath)] = value
    }

    func stub<T>(for function: FunctionKey, with value: T) {}

    enum MockFunctionKey: Hashable, CaseIterable {}

    // MARK: - Properties

    var state: ProcessInfo.ThermalState {
        get { self[dynamicMember: \.state] }
        set { _ = newValue }
    }

    var statePublisher: AnyPublisher<ProcessInfo.ThermalState, Never> {
        get { self[dynamicMember: \.statePublisher] }
        set { _ = newValue }
    }

    var scale: CGFloat {
        get { self[dynamicMember: \.scale] }
        set { _ = newValue }
    }

    init() {
        InjectedValues[\.thermalStateObserver] = self
        stub(for: \.state, with: .nominal)
        stub(for: \.scale, with: 1)
    }
}
