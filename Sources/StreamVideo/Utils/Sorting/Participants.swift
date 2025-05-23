//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// A comparator which sorts participants by whether they are the dominant speaker.
nonisolated(unsafe) public let dominantSpeaker: StreamSortComparator<CallParticipant> = { a, b in
    if a.isDominantSpeaker && !b.isDominantSpeaker { return .orderedAscending }
    if !a.isDominantSpeaker && b.isDominantSpeaker { return .orderedDescending }
    return .orderedSame
}

/// A comparator which sorts participants by whether they are speaking.
nonisolated(unsafe) public let speaking: StreamSortComparator<CallParticipant> = { a, b in
    if a.isSpeaking && !b.isSpeaking { return .orderedAscending }
    if !a.isSpeaking && b.isSpeaking { return .orderedDescending }
    return .orderedSame
}

nonisolated(unsafe) public let isSpeaking = speaking

/// A comparator which sorts participants by screen sharing status.
nonisolated(unsafe) public let screenSharing: StreamSortComparator<CallParticipant> = { a, b in
    if a.isScreensharing && !b.isScreensharing { return .orderedAscending }
    if !a.isScreensharing && b.isScreensharing { return .orderedDescending }
    return .orderedSame
}

/// A comparator which sorts participants by video status.
nonisolated(unsafe) public let publishingVideo: StreamSortComparator<CallParticipant> = { a, b in
    if a.hasVideo && !b.hasVideo { return .orderedAscending }
    if !a.hasVideo && b.hasVideo { return .orderedDescending }
    return .orderedSame
}

/// A comparator which sorts participants by audio status.
nonisolated(unsafe) public let publishingAudio: StreamSortComparator<CallParticipant> = { a, b in
    if a.hasAudio && !b.hasAudio { return .orderedAscending }
    if !a.hasAudio && b.hasAudio { return .orderedDescending }
    return .orderedSame
}

/// A comparator which prioritizes participants who are pinned.
nonisolated(unsafe) public let pinned: StreamSortComparator<CallParticipant> = { a, b in
    if let aPin = a.pin, let bPin = b.pin {
        if !aPin.isLocal && bPin.isLocal { return .orderedAscending }
        if aPin.isLocal && !bPin.isLocal { return .orderedDescending }
        if aPin.pinnedAt > bPin.pinnedAt { return .orderedAscending }
        if aPin.pinnedAt < bPin.pinnedAt { return .orderedDescending }
    }

    if a.pin != nil && b.pin == nil { return .orderedAscending }
    if a.pin == nil && b.pin != nil { return .orderedDescending }

    return .orderedSame
}

/// A comparator creator which sets up a comparator prioritizing participants who have a specific role.
nonisolated public func roles(_ roles: [String] = ["admin", "host", "speaker"]) -> StreamSortComparator<CallParticipant> {
    { a, b in
        if hasAnyRole(a, roles) && !hasAnyRole(b, roles) { return .orderedAscending }
        if !hasAnyRole(a, roles) && hasAnyRole(b, roles) { return .orderedDescending }
        return .orderedSame
    }
}

/// A comparator which sorts participants by name.
nonisolated(unsafe) public let name: StreamSortComparator<CallParticipant> = { a, b in
    a.name.localizedCompare(b.name)
}

/// Helper function to check if a participant has any of the specified roles.
nonisolated private func hasAnyRole(_ participant: CallParticipant, _ roles: [String]) -> Bool {
    participant.roles.contains(where: roles.contains)
}

/// Comparator for sorting `CallParticipant` objects based on their `id` property
nonisolated(unsafe) public var id: StreamSortComparator<CallParticipant> = { comparison($0, $1, keyPath: \.id) }

/// Comparator for sorting `CallParticipant` objects based on their `userId` property
nonisolated(unsafe) public var userId: StreamSortComparator<CallParticipant> = { comparison($0, $1, keyPath: \.userId) }

/// Comparator for sorting `CallParticipant` objects based on the date and time (`joinedAt`) they joined the call
nonisolated(unsafe) public var joinedAt: StreamSortComparator<CallParticipant> = { comparison($0, $1, keyPath: \.joinedAt) }
