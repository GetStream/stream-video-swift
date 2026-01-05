//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

// MARK: - Sort Sequence

/// Represents the possible orders for sorting.
public enum StreamSortOrder {
    case ascending, descending

    /// Converts `StreamSortOrder` to `Foundation.SortOrder`.
    ///
    /// - Returns: A `SortOrder` value corresponding to the enum case.
    ///   `.forward` for `.ascending` and `.reverse` for `.descending`.
    @available(iOS 15.0, *)
    var rawValue: SortOrder {
        switch self {
        case .ascending:
            return .forward
        case .descending:
            return .reverse
        }
    }
}

extension Sequence where Element == CallParticipant {

    /// Sorts the sequence's elements using a specified comparator and order.
    ///
    /// - Parameters:
    ///   - comparator: The comparator function used to determine the order of two elements.
    ///   - order: The desired sort order, either `.ascending` (default) or `.descending`.
    /// - Returns: A sorted array of `CallParticipant`.
    public func sorted(
        by comparator: StreamSortComparator<Element>,
        order: StreamSortOrder = .ascending
    ) -> [Element] {
        sorted {
            switch order {
            case .ascending:
                return comparator($0, $1) == .orderedAscending
            case .descending:
                return comparator($0, $1) == .orderedDescending
            }
        }
    }

    /// Sorts the sequence's elements using multiple comparators and a specified order.
    /// The comparators are applied in the order they are provided.
    ///
    /// - Parameters:
    ///   - comparators: An array of comparator functions used to determine the order of two elements.
    ///   - order: The desired sort order, either `.ascending` (default) or `.descending`.
    /// - Returns: A sorted array of `CallParticipant`.
    public func sorted(
        by comparators: [StreamSortComparator<Element>],
        order: StreamSortOrder = .ascending
    ) -> [Element] { sorted(by: combineComparators(comparators), order: order) }
}

// MARK: - Comparison operations

/// Compares two `Value` objects based on a specified property (via `KeyPath`) that conforms to `Comparable`.
/// Returns a `ComparisonResult` indicating the ordering of the two objects based on that property.
///
/// - Parameters:
///   - lhs: The left-hand side object for comparison.
///   - rhs: The right-hand side object for comparison.
///   - keyPath: The key path to a property of `Value` that should be used for comparison.
/// - Returns: A `ComparisonResult` value indicating the ordering of `lhs` and `rhs` based on the property.
func comparison<Value, T: Comparable>(
    _ lhs: Value,
    _ rhs: Value,
    keyPath: KeyPath<Value, T>
) -> ComparisonResult {
    let lhsValue = lhs[keyPath: keyPath]
    let rhsValue = rhs[keyPath: keyPath]

    if lhsValue < rhsValue {
        return .orderedAscending
    } else if lhsValue > rhsValue {
        return .orderedDescending
    } else {
        return .orderedSame
    }
}

/// Compares two `Value` objects based on a specified boolean property (via `KeyPath`).
/// Returns a `ComparisonResult` indicating the ordering of the two objects based on that property.
/// Note: `true` is considered less than `false`.
///
/// - Parameters:
///   - lhs: The left-hand side object for comparison.
///   - rhs: The right-hand side object for comparison.
///   - keyPath: The key path to a boolean property of `Value` that should be used for comparison.
/// - Returns: A `ComparisonResult` value indicating the ordering of `lhs` and `rhs` based on the property.
func comparison<Value>(
    _ lhs: Value,
    _ rhs: Value,
    keyPath: KeyPath<Value, Bool>
) -> ComparisonResult {
    let lhsValue = lhs[keyPath: keyPath]
    let rhsValue = rhs[keyPath: keyPath]

    switch (lhsValue, rhsValue) {
    case (true, false):
        return .orderedAscending
    case (false, true):
        return .orderedDescending
    default:
        return .orderedSame
    }
}
