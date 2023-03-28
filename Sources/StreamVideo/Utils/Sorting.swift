//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

public typealias Comparator<Value> = (Value, Value) -> ComparisonResult

public var screensharing: Comparator<CallParticipant> = { (p1, p2) in
    booleanComparison(first: p1, second: p2, \.isScreensharing)
}

public var dominantSpeaker: Comparator<CallParticipant> = { (p1, p2) in
    booleanComparison(first: p1, second: p2, \.isDominantSpeaker)
}

public var isSpeaking: Comparator<CallParticipant> = { (p1, p2) in
    booleanComparison(first: p1, second: p2, \.isSpeaking)
}

public var publishingVideo: Comparator<CallParticipant> = { (p1, p2) in
    booleanComparison(first: p1, second: p2, \.hasVideo)
}

public var publishingAudio: Comparator<CallParticipant> = { (p1, p2) in
    booleanComparison(first: p1, second: p2, \.hasAudio)
}

public var userId: Comparator<CallParticipant> = { (p1, p2) in
    p1.id >= p2.id ? .orderedDescending : .orderedAscending
}

extension Sequence {
    func sorted(using comparators: [Comparator<Element>], order: SortOrder = .descending) -> [Element] {
        sorted { valueA, valueB in
            for comparator in comparators {
                let result = comparator(valueA, valueB)

                switch result {
                case .orderedSame:
                    break
                case .orderedAscending:
                    return order == .ascending
                case .orderedDescending:
                    return order == .descending
                }
            }

            // If no descriptor was able to determine the sort
            // order, we'll default to false (similar to when
            // using the '<' operator with the built-in API):
            return false
        }
    }
}

enum SortOrder {
    case ascending
    case descending
}

func booleanComparison<Value, T>(
    first: Value,
    second: Value,
    _ keyPath: KeyPath<Value, T>
) -> ComparisonResult {
    let boolFirst = first[keyPath: keyPath] as? Bool
    let boolSecond = second[keyPath: keyPath] as? Bool
    if boolFirst == boolSecond { return .orderedSame }
    if boolFirst == true { return .orderedDescending }
    if boolSecond == true { return .orderedAscending }
    return .orderedSame
}
