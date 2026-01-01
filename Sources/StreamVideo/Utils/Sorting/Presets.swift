//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A comparator decorator which applies the decorated comparator only if the participant is invisible.
/// This ensures stable sorting when all participants are visible.
public nonisolated(unsafe) let ifInvisibleBy = conditional { (a: CallParticipant, b: CallParticipant) in
    a.showTrack == false || b.showTrack == false
}

public nonisolated(unsafe) let ifInvisible = ifInvisibleBy

/// The default sorting preset.
public nonisolated(unsafe) let defaultSortPreset = [
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

public nonisolated(unsafe) let defaultComparators = defaultSortPreset

/// The sorting preset for speaker layout.
public nonisolated(unsafe) let speakerLayoutSortPreset = [
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

public nonisolated(unsafe) let screensharing = speakerLayoutSortPreset

/// The sorting preset for layouts that don't render all participants but instead, render them in pages.
public nonisolated(unsafe) let paginatedLayoutSortPreset = [
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
public nonisolated(unsafe) let livestreamOrAudioRoomSortPreset = [
    ifInvisibleBy(
        combineComparators(
            [
                dominantSpeaker,
                speaking,
                participantSource(.rtmp),
                publishingVideo,
                publishingAudio
            ]
        )
    ),
    roles()
]
