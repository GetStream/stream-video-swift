//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// A comparator decorator which applies the decorated comparator only if the participant is invisible.
/// This ensures stable sorting when all participants are visible.
nonisolated(unsafe) public let ifInvisibleBy = conditional { (a: CallParticipant, b: CallParticipant) in
    a.showTrack == false || b.showTrack == false
}

nonisolated(unsafe) public let ifInvisible = ifInvisibleBy

/// The default sorting preset.
nonisolated(unsafe) public let defaultSortPreset = [
    pinned,
    screenSharing,
    ifInvisibleBy(
        combineComparators(
            [
                dominantSpeaker,
                speaking,
                publishingVideo,
                publishingAudio
            ]
        )
    ),
    ifInvisibleBy(userId)
]

nonisolated(unsafe) public let defaultComparators = defaultSortPreset

/// The sorting preset for speaker layout.
nonisolated(unsafe) public let speakerLayoutSortPreset = [
    pinned,
    screenSharing,
    dominantSpeaker,
    ifInvisibleBy(
        combineComparators(
            [
                speaking,
                publishingVideo,
                publishingAudio
            ]
        )
    ),
    ifInvisibleBy(userId)
]

nonisolated(unsafe) public let screensharing = speakerLayoutSortPreset

/// The sorting preset for layouts that don't render all participants but instead, render them in pages.
nonisolated(unsafe) public let paginatedLayoutSortPreset = [
    pinned,
    ifInvisibleBy(
        combineComparators(
            [
                dominantSpeaker,
                speaking,
                publishingVideo,
                publishingAudio
            ]
        )
    ),
    ifInvisibleBy(userId)
]

/// The sorting preset for livestreams and audio rooms.
nonisolated(unsafe) public let livestreamOrAudioRoomSortPreset = [
    ifInvisibleBy(
        combineComparators(
            [
                dominantSpeaker,
                speaking,
                publishingVideo,
                publishingAudio
            ]
        )
    ),
    roles()
]
