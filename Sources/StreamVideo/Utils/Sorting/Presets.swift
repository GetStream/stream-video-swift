//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// A comparator decorator which applies the decorated comparator only if the participant is invisible.
/// This ensures stable sorting when all participants are visible.
public let ifInvisibleBy = conditional { (a: CallParticipant, b: CallParticipant) in
    a.showTrack == false || b.showTrack == false
}

/// The default sorting preset.
public let defaultSortPreset = combineComparators(
    pinned,
    screenSharing,
    ifInvisibleBy(
        combineComparators(
            dominantSpeaker,
            speaking,
            publishingVideo,
            publishingAudio
        )
    )
    // ifInvisibleBy(name),
)

/// The sorting preset for speaker layout.
public let speakerLayoutSortPreset = combineComparators(
    pinned,
    screenSharing,
    dominantSpeaker,
    ifInvisibleBy(
        combineComparators(
            speaking,
            publishingVideo,
            publishingAudio
        )
    )
    // ifInvisibleBy(name),
)

/// The sorting preset for layouts that don't render all participants but instead, render them in pages.
public let paginatedLayoutSortPreset = combineComparators(
    pinned,
    ifInvisibleBy(
        combineComparators(
            dominantSpeaker,
            speaking,
            publishingVideo,
            publishingAudio
        )
    )
    // ifInvisibleOrUnknownBy(name),
)

/// The sorting preset for livestreams and audio rooms.
public let livestreamOrAudioRoomSortPreset = combineComparators(
    ifInvisibleBy(
        combineComparators(
            dominantSpeaker,
            speaking,
            publishingVideo,
            publishingAudio
        )
    ),
    role("admin", "host", "speaker")
)
