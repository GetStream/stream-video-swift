//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type representing a comparator function that compares two `Value` objects and returns a `ComparisonResult`.
public typealias StreamSortComparator<Value> = (Value, Value) -> ComparisonResult

/// The default set of comparators used for sorting `CallParticipant` objects.
/// - `pinned`: Prioritizes participants who are pinned.
/// - `screensharing`: Sorts participants based on their screen sharing status.
/// - `dominantSpeaker`: Sorts participants based on whether they are the dominant speaker or not.
/// - `ifInvisible(isSpeaking)`: Sorts participants based on whether they are speaking, but only if they are not visible.
/// - `ifInvisible(publishingVideo)`: Sorts participants based on their video status, but only if they are not visible.
/// - `ifInvisible(publishingAudio)`: Sorts participants based on their audio status, but only if they are not visible.
public let defaultComparators: [StreamSortComparator<CallParticipant>] = [
    pinned,
    screensharing,
    dominantSpeaker,
    ifInvisible(isSpeaking),
    ifInvisible(publishingVideo),
    ifInvisible(publishingAudio),
    ifInvisible(userId)
]

/// The set of comparators used for sorting `CallParticipant` objects during livestreams.
/// - `ifInvisible(dominantSpeaker)`: Sorts participants based on whether they are the dominant speaker or not, but only if they are not visible.
/// - `ifInvisible(isSpeaking)`: Sorts participants based on whether they are speaking, but only if they are not visible.
/// - `ifInvisible(publishingVideo)`: Sorts participants based on their video status, but only if they are not visible.
/// - `ifInvisible(publishingAudio)`: Sorts participants based on their audio status, but only if they are not visible.
/// - `roles()`: Sorts participants based on their assigned roles.
public let livestreamComparators: [StreamSortComparator<CallParticipant>] = [
    ifInvisible(dominantSpeaker),
    ifInvisible(isSpeaking),
    ifInvisible(publishingVideo),
    ifInvisible(publishingAudio),
    roles(),
    joinedAt,
    userId
]

// MARK: - Sort Sequence

/// Represents the possible orders for sorting.
public enum StreamSortOrder { case ascending, descending }

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

// MARK: - Comparators

// MARK: Aggregators

/// Combines multiple comparators into a single comparator.
/// It uses the first comparator to compare two elements. If they are deemed "equal" (i.e., orderedSame),
/// it moves to the next comparator, and so on, until a decision can be made or all comparators have been exhausted.
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

/// Returns a new comparator that only applies the given comparator if the predicate returns true.
/// If the predicate returns false, it deems the two elements "equal" (i.e., orderedSame).
public func conditional<T>(_ predicate: @escaping (T, T) -> Bool)
    -> (@escaping StreamSortComparator<T>) -> StreamSortComparator<T> {
    { comparator in
        { a, b in
            if !predicate(a, b) {
                return .orderedSame
            }
            return comparator(a, b)
        }
    }
}

/// A specific conditional comparator for CallParticipant that checks if either participant's track is not visible.
public let ifInvisible = conditional { (lhs: CallParticipant, rhs: CallParticipant) -> Bool in
    !lhs.showTrack || !rhs.showTrack
}

// MARK: Instance

/// Comparator which sorts participants by the fact that they are the dominant speaker or not.
public var dominantSpeaker: StreamSortComparator<CallParticipant> = { comparison($0, $1, keyPath: \.isDominantSpeaker) }

/// Comparator which sorts participants by the fact that they are speaking or not.
public var isSpeaking: StreamSortComparator<CallParticipant> = { comparison($0, $1, keyPath: \.isSpeaking) }

/// Comparator which prioritizes participants who are pinned.
/// - Note: Remote pins have higher priority than local.
public var pinned: StreamSortComparator<CallParticipant> = { a, b in
    switch (a.pin, b.pin) {
    case (nil, _?): return .orderedDescending
    case (_?, nil): return .orderedAscending
    case let (aPin?, bPin?) where aPin.isLocal && !bPin.isLocal: return .orderedAscending
    case let (aPin?, bPin?) where !aPin.isLocal && bPin.isLocal: return .orderedDescending
    case let (aPin?, bPin?) where aPin.pinnedAt > bPin.pinnedAt: return .orderedAscending
    case let (aPin?, bPin?) where aPin.pinnedAt < bPin.pinnedAt: return .orderedDescending
    default: return .orderedSame
    }
}

/// Comparator which sorts participants by screen sharing status.
public var screensharing: StreamSortComparator<CallParticipant> = { comparison($0, $1, keyPath: \.isScreensharing) }

/// Comparator which sorts participants by video status.
public var publishingVideo: StreamSortComparator<CallParticipant> = { comparison($0, $1, keyPath: \.hasVideo) }

/// Comparator which sorts participants by audio status.
public var publishingAudio: StreamSortComparator<CallParticipant> = { comparison($0, $1, keyPath: \.hasAudio) }

/// Comparator which sorts participants by name.
public var name: StreamSortComparator<CallParticipant> = { comparison($0, $1, keyPath: \.name) }

/// A comparator creator which will set up a comparator which prioritizes participants who have a specific role.
public func roles(_ priorityRoles: [String] = ["admin", "host", "speaker"]) -> StreamSortComparator<CallParticipant> {
    { (p1, p2) in
        if p1.roles == p2.roles { return .orderedSame }
        for role in priorityRoles {
            if p1.roles.contains(role) && !p2.roles.contains(role) {
                return .orderedAscending
            }
            if p2.roles.contains(role) && !p1.roles.contains(role) {
                return .orderedDescending
            }
        }
        return .orderedSame
    }
}

/// Comparator for sorting `CallParticipant` objects based on their `id` property
public var id: StreamSortComparator<CallParticipant> = { comparison($0, $1, keyPath: \.id) }

/// Comparator for sorting `CallParticipant` objects based on their `userId` property
public var userId: StreamSortComparator<CallParticipant> = { comparison($0, $1, keyPath: \.userId) }

/// Comparator for sorting `CallParticipant` objects based on the date and time (`joinedAt`) they joined the call
public var joinedAt: StreamSortComparator<CallParticipant> = { comparison($0, $1, keyPath: \.joinedAt) }
