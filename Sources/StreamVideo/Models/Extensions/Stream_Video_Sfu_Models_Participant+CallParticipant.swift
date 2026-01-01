//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension Stream_Video_Sfu_Models_Participant {
    func toCallParticipant(
        showTrack: Bool = true,
        pin: PinInfo? = nil
    ) -> CallParticipant {
        CallParticipant(
            id: sessionID,
            userId: userID,
            roles: roles,
            name: name,
            profileImageURL: URL(string: image),
            trackLookupPrefix: trackLookupPrefix,
            hasVideo: publishedTracks.contains(where: { $0 == .video }),
            hasAudio: publishedTracks.contains(where: { $0 == .audio }),
            isScreenSharing: publishedTracks.contains(where: { $0 == .screenShare }),
            showTrack: showTrack,
            isSpeaking: isSpeaking,
            isDominantSpeaker: isDominantSpeaker,
            sessionId: sessionID,
            connectionQuality: connectionQuality.mapped,
            joinedAt: joinedAt.date,
            audioLevel: audioLevel,
            audioLevels: [audioLevel],
            pin: pin,
            pausedTracks: [],
            source: .init(source)
        )
    }
}
