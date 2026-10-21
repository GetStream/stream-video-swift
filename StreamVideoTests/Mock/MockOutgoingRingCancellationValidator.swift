//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo

final class MockOutgoingRingCancellationValidator: OutgoingRingCancellationValidating, Mockable, @unchecked Sendable {
    typealias FunctionKey = MockFunctionKey

    enum MockFunctionKey: Hashable, CaseIterable {
        case validate
    }

    enum MockFunctionInputKey: Payloadable {
        case validate(call: Call, reason: String?, stateMachine: Call.StateMachine)

        var payload: Any {
            switch self {
            case let .validate(call, reason, stateMachine):
                return (call, reason, stateMachine)
            }
        }
    }

    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [FunctionKey: Any] = [:]
    @Atomic var stubbedFunctionInput: [FunctionKey: [MockFunctionInputKey]] = FunctionKey
        .allCases
        .reduce(into: [FunctionKey: [MockFunctionInputKey]]()) { $0[$1] = [] }

    func stub<T>(for keyPath: KeyPath<MockOutgoingRingCancellationValidator, T>, with value: T) {
        stubbedProperty[propertyKey(for: keyPath)] = value
    }

    func stub<T>(for function: FunctionKey, with value: T) {
        stubbedFunction[function] = value
    }

    @MainActor
    func validate(call: Call, reason: String?, stateMachine: Call.StateMachine) async throws {
        stubbedFunctionInput[.validate]?.append(.validate(call: call, reason: reason, stateMachine: stateMachine))
        if let error = stubbedFunction[.validate] as? Error {
            throw error
        }
    }
}
