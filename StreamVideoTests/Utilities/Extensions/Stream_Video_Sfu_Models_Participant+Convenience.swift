//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo

extension Stream_Video_Sfu_Models_Participant {

    init(_ source: CallParticipant) {
        self.init()
        sessionID = source.sessionId
        userID = source.userId
        roles = source.roles
        name = source.name
        image = source.profileImageURL?.absoluteString ?? ""
        trackLookupPrefix = source.trackLookupPrefix ?? ""
        var publishedTracks: [Stream_Video_Sfu_Models_TrackType] = []
        if source.hasAudio { publishedTracks.append(.audio) }
        if source.hasVideo { publishedTracks.append(.video) }
        if source.isScreensharing { publishedTracks.append(.screenShare) }
        self.publishedTracks = publishedTracks
        isSpeaking = source.isSpeaking
        isDominantSpeaker = source.isSpeaking
        connectionQuality = .init(source.connectionQuality)
        joinedAt = .init(date: source.joinedAt)
        audioLevel = source.audioLevel
    }
}
