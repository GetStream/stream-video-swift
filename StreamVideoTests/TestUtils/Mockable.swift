//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

protocol Payloadable {
    var payload: Any { get }
}

enum EmptyPayloadable: Payloadable { var payload: Any { () } }

@dynamicMemberLookup
protocol Mockable {

    associatedtype FunctionKey: Hashable & CaseIterable
    associatedtype FunctionInputKey: Payloadable

    var stubbedProperty: [String: Any] { get set }
    var stubbedFunction: [FunctionKey: Any] { get set }
    var stubbedFunctionInput: [FunctionKey: [FunctionInputKey]] { get set }

    func propertyKey(for keyPath: KeyPath<Self, some Any>) -> String

    static func propertyKey(for keyPath: KeyPath<Self, some Any>) -> String

    func stub<T>(for keyPath: KeyPath<Self, T>, with value: T)

    func stub(for function: FunctionKey, with value: some Any)
}

extension Mockable {

    func propertyKey(for keyPath: KeyPath<Self, some Any>) -> String {
        "\(keyPath)"
    }

    static func propertyKey(for keyPath: KeyPath<Self, some Any>) -> String {
        "\(keyPath)"
    }

    subscript<T>(dynamicMember keyPath: KeyPath<Self, T>) -> T {
        let value = stubbedProperty[propertyKey(for: keyPath)]
        return value as! T
    }

    func recordedInputPayload<T>(_ ofType: T.Type, for key: FunctionKey) -> [T]? {
        stubbedFunctionInput[key]?.compactMap { $0.payload as? T } as? [T]
    }

    func timesCalled(_ key: FunctionKey) -> Int { stubbedFunctionInput[key]?.count ?? 0 }

    mutating func resetRecords(for key: FunctionKey) {
        stubbedFunctionInput[key] = []
    }
}

final class StubVariantResultProvider<Value> {

    var provider: (Int) -> Value

    init(_ provider: @escaping (Int) -> Value) {
        self.provider = provider
    }

    func getResult(for iteration: Int) -> Value {
        provider(iteration)
    }
}
