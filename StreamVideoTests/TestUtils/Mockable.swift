//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

@dynamicMemberLookup
protocol Mockable {

    associatedtype FunctionKey: Hashable

    var stubbedProperty: [String: Any] { get set }
    var stubbedFunction: [FunctionKey: Any] { get set }

    func propertyKey<T>(for keyPath: KeyPath<Self, T>) -> String

    static func propertyKey<T>(for keyPath: KeyPath<Self, T>) -> String

    func stub<T>(for keyPath: KeyPath<Self, T>, with value: T)

    func stub<T>(for function: FunctionKey, with value: T)
}

extension Mockable {

    func propertyKey<T>(for keyPath: KeyPath<Self, T>) -> String {
        "\(keyPath)"
    }

    static func propertyKey<T>(for keyPath: KeyPath<Self, T>) -> String {
        "\(keyPath)"
    }

    subscript<T>(dynamicMember keyPath: KeyPath<Self, T>) -> T {
        let value = stubbedProperty[propertyKey(for: keyPath)]
        return value as! T
    }
}
