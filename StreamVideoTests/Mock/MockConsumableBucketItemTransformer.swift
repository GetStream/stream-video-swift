//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo

final class MockConsumableBucketItemTransformer<Input, Output>: ConsumableBucketItemTransformer, Mockable {

    // MARK: - Mockable

    typealias FunctionKey = MockFunctionKey
    typealias FunctionInputKey = MockFunctionInputKey
    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [FunctionKey: Any] = [:]
    @Atomic var stubbedFunctionInput: [FunctionKey: [FunctionInputKey]] = FunctionKey
        .allCases
        .reduce(into: [FunctionKey: [FunctionInputKey]]()) { $0[$1] = [] }
    func stub<T>(for keyPath: KeyPath<MockConsumableBucketItemTransformer, T>, with value: T) {
        stubbedProperty[propertyKey(for: keyPath)] = value
    }

    func stub<T>(for function: FunctionKey, with value: T) {}

    enum MockFunctionKey: Hashable, CaseIterable {
        case transform
    }

    enum MockFunctionInputKey: Payloadable {
        case transform(input: Input)

        var payload: Any {
            switch self {
            case let .transform(input):
                return input
            }
        }
    }

    func transform(_ input: Input) -> Output {
        stubbedFunctionInput[.transform]?.append(.transform(input: input))
        return stubbedFunction[.transform] as! Output
    }
}
