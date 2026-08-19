//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A comparator which sorts participants by whether they are the dominant
/// speaker.
public nonisolated(unsafe) let dominantSpeaker: StreamSortComparator<CallParticipant> = { a, b in
    if a.isDominantSpeaker && !b.isDominantSpeaker { return .orderedAscending }
    if !a.isDominantSpeaker && b.isDominantSpeaker { return .orderedDescending }
    return .orderedSame
}

/// A comparator which sorts participants by whether they are speaking.
public nonisolated(unsafe) let speaking: StreamSortComparator<CallParticipant> = { a, b in
    if a.isSpeaking && !b.isSpeaking { return .orderedAscending }
    if !a.isSpeaking && b.isSpeaking { return .orderedDescending }
    return .orderedSame
}

public nonisolated(unsafe) let isSpeaking = speaking

/// A comparator which sorts participants by screen sharing status.
public nonisolated(unsafe) let screenSharing: StreamSortComparator<CallParticipant> = { a, b in
    if a.isScreensharing && !b.isScreensharing { return .orderedAscending }
    if !a.isScreensharing && b.isScreensharing { return .orderedDescending }
    return .orderedSame
}

/// A comparator which sorts participants by video status.
public nonisolated(unsafe) let publishingVideo: StreamSortComparator<CallParticipant> = { a, b in
    if a.hasVideo && !b.hasVideo { return .orderedAscending }
    if !a.hasVideo && b.hasVideo { return .orderedDescending }
    return .orderedSame
}

/// A comparator which sorts participants by audio status.
public nonisolated(unsafe) let publishingAudio: StreamSortComparator<CallParticipant> = { a, b in
    if a.hasAudio && !b.hasAudio { return .orderedAscending }
    if !a.hasAudio && b.hasAudio { return .orderedDescending }
    return .orderedSame
}

/// A comparator which prioritizes participants who are pinned.
public nonisolated(unsafe) let pinned: StreamSortComparator<CallParticipant> = { a, b in
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

/// The reaction types the SDKs use for a raised hand.
///
/// The value differs across platforms: the JavaScript SDK sends
/// `raised-hand` as the reaction type and `:raise-hand:` as the emoji code,
/// while the Android SDK and the iOS demo application send `:raise-hand:` as
/// the type. ``raisedHand`` matches all of them so ordering works in a call
/// with participants from any platform.
public let raisedHandReactionTypes: Set<String> = [
    "raised-hand",
    ":raise-hand:"
]

/// A comparator creator which sets up a comparator prioritizing participants
/// who sent a reaction of the given type.
public nonisolated func reactionType(_ type: String) -> StreamSortComparator<CallParticipant> {
    reactionTypes([type])
}

/// A comparator creator which sets up a comparator prioritizing participants
/// who sent a reaction matching any of the given types.
public nonisolated func reactionTypes(_ types: Set<String>) -> StreamSortComparator<CallParticipant> {
    { a, b in
        /// Most participants hold no reactions for most of a call, so this
        /// avoids the lookups on the hot path of sorting large calls.
        if a.reactions.isEmpty, b.reactions.isEmpty { return .orderedSame }

        let aHas = a.reactions.contains { types.contains($0.type) }
        let bHas = b.reactions.contains { types.contains($0.type) }
        if aHas && !bHas { return .orderedAscending }
        if !aHas && bHas { return .orderedDescending }
        return .orderedSame
    }
}

/// A comparator which sorts participants with a raised hand first.
public nonisolated(unsafe) let raisedHand: StreamSortComparator<CallParticipant> = reactionTypes(
    raisedHandReactionTypes
)

/// A comparator creator which sets up a comparator prioritizing participants
/// who have a specific role.
public nonisolated func roles(_ roles: [String] = ["admin", "host", "speaker"]) -> StreamSortComparator<CallParticipant> {
    { a, b in
        if hasAnyRole(a, roles) && !hasAnyRole(b, roles) { return .orderedAscending }
        if !hasAnyRole(a, roles) && hasAnyRole(b, roles) { return .orderedDescending }
        return .orderedSame
    }
}

/// A comparator which sorts participants by name.
public nonisolated(unsafe) let name: StreamSortComparator<CallParticipant> = { a, b in
    a.name.localizedCompare(b.name)
}

/// Helper function to check if a participant has any of the specified roles.
private nonisolated func hasAnyRole(_ participant: CallParticipant, _ roles: [String]) -> Bool {
    participant.roles.contains(where: roles.contains)
}

/// Comparator for sorting `CallParticipant` objects based on their `id`
/// property
public nonisolated(unsafe) var id: StreamSortComparator<CallParticipant> = { comparison($0, $1, keyPath: \.id) }

/// Comparator for sorting `CallParticipant` objects based on their `userId`
/// property
public nonisolated(unsafe) var userId: StreamSortComparator<CallParticipant> = { comparison($0, $1, keyPath: \.userId) }

/// Comparator for sorting `CallParticipant` objects based on the date and time
/// (`joinedAt`) they joined the call
public nonisolated(unsafe) var joinedAt: StreamSortComparator<CallParticipant> = { comparison($0, $1, keyPath: \.joinedAt) }

/// Comparator that prioritizes participants whose `source` matches the given
/// value.
/// Use this to surface ingest or SIP participants before others.
public nonisolated func participantSource(_ source: ParticipantSource) -> StreamSortComparator<CallParticipant> {
    { a, b in
        if a.source == source && b.source != source { return .orderedAscending }
        if a.source != source && b.source == source { return .orderedDescending }
        return .orderedSame
    }
}

/// A comparator creator that ranks participants by their source priority.
/// Sources listed earlier take precedence; participants with unlisted sources
/// are ranked last.
public nonisolated func withParticipantSources(_ sources: [ParticipantSource]) -> StreamSortComparator<CallParticipant> {
    { a, b in
        let priorityA = sources.firstIndex(of: a.source) ?? Int.max
        let priorityB = sources.firstIndex(of: b.source) ?? Int.max
        if priorityA < priorityB { return .orderedAscending }
        if priorityA > priorityB { return .orderedDescending }
        return .orderedSame
    }
}

/// A comparator that surfaces video-ingest participants (RTMP, SRT, WHIP, RTSP)
/// ahead of regular WebRTC participants, in that priority order.
public nonisolated(unsafe) let videoIngressSource: StreamSortComparator<CallParticipant> =
    withParticipantSources([.rtmp, .srt, .whip, .rtsp])
