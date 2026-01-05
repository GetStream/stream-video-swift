//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A protocol for types capable of providing UUIDs.
public protocol UUIDProviding {
    /// Generates and returns a UUID.
    func get() -> UUID
}

/// A key used for dependency injection of UUID providers.
public enum UUIDProviderKey: InjectionKey {
    /// The current value of UUID provider, defaulted to `StreamUUIDFactory`.
    public nonisolated(unsafe) static var currentValue: UUIDProviding = StreamUUIDFactory()
}

extension InjectedValues {
    /// Accesses or sets the UUID provider for dependency injection.
    ///
    /// Example:
    /// ```swift
    /// // Accessing UUID factory
    /// let uuidProvider = InjectedValues[\.uuidFactory]
    ///
    /// // Setting a new UUID factory
    /// InjectedValues[\.uuidFactory].uuidFactory = CustomUUIDFactory()
    /// ```
    public var uuidFactory: UUIDProviding {
        get { Self[UUIDProviderKey.self] }
        set { Self[UUIDProviderKey.self] = newValue }
    }
}

/// A UUID provider implementation that generates UUIDs using `UUID.init()`.
public struct StreamUUIDFactory: UUIDProviding {
    /// Generates and returns a UUID.
    public func get() -> UUID { UUID() }
}
