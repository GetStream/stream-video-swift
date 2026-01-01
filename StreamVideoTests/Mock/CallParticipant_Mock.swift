//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamWebRTC

extension CallParticipant {

    static func dummy(
        id: String = .unique,
        userId: String? = nil,
        roles: [String] = [],
        name: String = .unique,
        profileImageURL: URL? = nil,
        trackLookupPrefix: String = "",
        hasVideo: Bool = false,
        hasAudio: Bool = false,
        isScreenSharing: Bool = false,
        showTrack: Bool = false,
        track: RTCVideoTrack? = nil,
        trackSize: CGSize = CGSize(width: 1024, height: 720),
        screenshareTrack: RTCVideoTrack? = nil,
        isSpeaking: Bool = false,
        isDominantSpeaker: Bool = false,
        sessionId: String? = nil,
        connectionQuality: ConnectionQuality = .unknown,
        joinedAt: Date = .init(timeIntervalSince1970: 0),
        audioLevel: Float = 0,
        audioLevels: [Float] = [],
        pin: PinInfo? = nil,
        pausedTracks: Set<TrackType> = [],
        source: ParticipantSource = .webRTCUnspecified
    ) -> CallParticipant {
        .init(
            id: id,
            userId: userId ?? id,
            roles: roles,
            name: name,
            profileImageURL: profileImageURL,
            trackLookupPrefix: trackLookupPrefix,
            hasVideo: hasVideo,
            hasAudio: hasAudio,
            isScreenSharing: isScreenSharing,
            showTrack: showTrack,
            track: track,
            trackSize: trackSize,
            screenshareTrack: screenshareTrack,
            isSpeaking: isSpeaking,
            isDominantSpeaker: isDominantSpeaker,
            sessionId: sessionId ?? id,
            connectionQuality: connectionQuality,
            joinedAt: joinedAt,
            audioLevel: audioLevel,
            audioLevels: audioLevels,
            pin: pin,
            pausedTracks: pausedTracks,
            source: source
        )
    }
}
