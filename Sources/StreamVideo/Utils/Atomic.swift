//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// A mutable thread safe variable.
///
/// - Warning: Be aware that accessing and setting a value are two distinct operations, so using operators like `+=` results
///  in two separate atomic operations. To work around this issue, you can access the wrapper directly and use the
///  `mutate(_ changes:)` method:
///  ```
///    // Correct
///    atomicValue = 1
///    let value = atomicValue
///
///    atomicValue += 1 // Incorrect! Accessing and setting a value are two atomic operations.
///    _atomicValue.mutate { $0 += 1 } // Correct
///    _atomicValue { $0 += 1 } // Also possible
///  ```
///
/// - Note: Even though the value guarded by `Atomic` is thread-safe, the `Atomic` class itself is not. Mutating the instance
/// itself from multiple threads can cause a crash.

@propertyWrapper
public final class Atomic<T>: @unchecked Sendable {
    public enum Mode {
        case unfair
        case recursive

        var queue: LockQueuing {
            switch self {
            case .unfair:
                return UnfairQueue()
            case .recursive:
                return RecursiveQueue()
            }
        }
    }

    private let queue: LockQueuing
    nonisolated(unsafe) private var _value: T

    public var wrappedValue: T {
        get { queue.sync { _value } }
        set { queue.sync { _value = newValue } }
    }

    public init(wrappedValue: T, mode: Mode = .unfair) {
        _value = wrappedValue
        queue = mode.queue
    }

    /// Update the value safely.
    /// - Parameter changes: a block with changes. It should return a new value.
    func mutate(_ changes: (_ value: T) -> T) {
        queue.sync { _value = changes(_value) }
    }
    
    /// Update the value safely.
    /// - Parameter changes: a block with changes. It should return a new value.
    func callAsFunction(_ changes: (_ value: T) -> T) { mutate(changes) }
}
