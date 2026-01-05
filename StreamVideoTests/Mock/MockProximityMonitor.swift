//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamVideo

final class MockProximityMonitor: ProximityProviding, Mockable {

    // MARK: - Mockable

    typealias FunctionKey = MockFunctionKey
    typealias FunctionInputKey = MockFunctionInputKey
    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [FunctionKey: Any] = [:]
    @Atomic var stubbedFunctionInput: [FunctionKey: [FunctionInputKey]] = FunctionKey
        .allCases
        .reduce(into: [FunctionKey: [FunctionInputKey]]()) { $0[$1] = [] }
    func stub<T>(for keyPath: KeyPath<MockProximityMonitor, T>, with value: T) {
        stubbedProperty[propertyKey(for: keyPath)] = value
    }

    func stub<T>(for function: FunctionKey, with value: T) {}

    enum MockFunctionKey: Hashable, CaseIterable {
        case startObservation, stopObservation
    }

    enum MockFunctionInputKey: Hashable, CaseIterable, Payloadable {
        case startObservation, stopObservation

        var payload: Any {
            ()
        }
    }

    var state: ProximityState {
        get { self[dynamicMember: \.state] }
        set { _ = newValue }
    }

    var statePublisher: AnyPublisher<ProximityState, Never> {
        get { self[dynamicMember: \.statePublisher] }
        set { _ = newValue }
    }

    var isActive: Bool {
        get { self[dynamicMember: \.isActive] }
        set { _ = newValue }
    }

    init() {
        ProximityProviderKey.currentValue = self
        stub(for: \.state, with: .far)
        stub(for: \.statePublisher, with: Just(ProximityState.far).eraseToAnyPublisher())
        stub(for: \.isActive, with: false)
    }

    func startObservation() {
        stubbedFunctionInput[.startObservation]?.append(.startObservation)
    }
    
    func stopObservation() {
        stubbedFunctionInput[.stopObservation]?.append(.stopObservation)
    }
}
