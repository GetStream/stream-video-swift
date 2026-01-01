//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo

final class MockProximityPolicy: ProximityPolicy, Mockable, @unchecked Sendable {

    // MARK: - Mockable

    typealias FunctionKey = MockFunctionKey
    typealias FunctionInputKey = MockFunctionInputKey
    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [FunctionKey: Any] = [:]
    @Atomic var stubbedFunctionInput: [FunctionKey: [FunctionInputKey]] = FunctionKey
        .allCases
        .reduce(into: [FunctionKey: [FunctionInputKey]]()) { $0[$1] = [] }
    func stub<T>(for keyPath: KeyPath<MockProximityPolicy, T>, with value: T) {
        stubbedProperty[propertyKey(for: keyPath)] = value
    }

    func stub<T>(for function: FunctionKey, with value: T) {}

    enum MockFunctionKey: Hashable, CaseIterable {
        case didUpdateProximity
    }

    enum MockFunctionInputKey: Payloadable {
        case didUpdateProximity(proximityState: ProximityState, call: Call)

        var payload: Any {
            switch self {
            case let .didUpdateProximity(proximityState, call):
                return (proximityState, call)
            }
        }
    }

    static let identifier: ObjectIdentifier = .init(String.unique as NSString)

    func didUpdateProximity(
        _ proximity: ProximityState,
        on call: Call
    ) {
        stubbedFunctionInput[.didUpdateProximity]?.append(
            .didUpdateProximity(
                proximityState: proximity,
                call: call
            )
        )
    }
}
