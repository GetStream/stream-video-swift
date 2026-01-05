//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Defines a comparator function which can be used for sorting items.
public typealias StreamSortComparator<T> = (T, T) -> ComparisonResult

/// Creates a new combined comparator which sorts items by the given comparators.
/// The comparators are applied in the order they are given (left -> right).
///
/// - Parameter comparators: The comparators to use for sorting.
/// - Returns: A combined comparator that applies each comparator in order.

public func combineComparators<T>(_ comparators: [StreamSortComparator<T>]) -> StreamSortComparator<T> {
    { a, b in
        for comparator in comparators {
            let result = comparator(a, b)
            if result != .orderedSame {
                return result
            }
        }
        return .orderedSame
    }
}

/// Creates a new comparator which sorts items in descending order.
///
/// - Parameter comparator: The comparator to wrap.
/// - Returns: A new comparator that reverses the order of the given comparator.
public func descending<T>(_ comparator: @escaping StreamSortComparator<T>) -> StreamSortComparator<T> {
    { a, b in comparator(b, a) }
}

/// Creates a new comparator which conditionally applies the given comparator.
///
/// - Parameter predicate: The predicate to use for determining whether to apply the comparator.
/// - Returns: A function that takes a comparator and applies it only if the predicate returns `true`.
public func conditional<T>(
    _ predicate: @escaping (T, T) -> Bool
) -> (@escaping StreamSortComparator<T>) -> StreamSortComparator<T> {
    { comparator in
        { a, b in
            guard predicate(a, b) else { return .orderedSame }
            return comparator(a, b)
        }
    }
}

/// A no-op comparator which always returns `.orderedSame`.
///
/// - Returns: A comparator that always returns `.orderedSame`.
public func noopComparator<T>() -> StreamSortComparator<T> {
    { _, _ in .orderedSame }
}
