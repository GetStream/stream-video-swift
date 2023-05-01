//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

public typealias Comparator<Value> = (Value, Value) -> ComparisonResult

public let defaultComparators: [Comparator<CallParticipant>] = [
    pinned, screensharing, dominantSpeaker, publishingVideo, publishingAudio, userId
]

public let livestreamComparators: [Comparator<CallParticipant>] = [
    dominantSpeaker, isSpeaking, publishingVideo, publishingAudio, roles, userId
]

public var pinned: Comparator<CallParticipant> = { (p1, p2) in
    booleanComparison(first: p1, second: p2, \.isPinned)
}

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

public var roles: Comparator<CallParticipant> = { (p1, p2) in
    if p1.roles == p2.roles { return .orderedSame }
    let prioRoles = ["admin", "host", "speaker"]
    for role in prioRoles {
        if p1.roles.contains(role) && !p2.roles.contains(role) {
            return .orderedDescending
        }
        if p2.roles.contains(role) && !p1.roles.contains(role) {
            return .orderedAscending
        }
    }
    return .orderedSame
}

public var userId: Comparator<CallParticipant> = { (p1, p2) in
    p1.id >= p2.id ? .orderedDescending : .orderedAscending
}

public extension Sequence {
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

            return false
        }
    }
}

public enum SortOrder {
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
