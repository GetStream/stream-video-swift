//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
@preconcurrency import WebRTC

/// Represents a participant in the call.
public struct CallParticipant: Identifiable, Sendable, Equatable {
    /// The unique call id of the participant.
    public var id: String
    /// The user's id. This is not necessarily unique, since a user can join from multiple devices.
    public let userId: String
    /// The user's roles in the call.
    public let roles: [String]
    /// The user's name.
    public let name: String
    /// The user's profile image url.
    public let profileImageURL: URL?
    /// The id of the track that's connected to the participant.
    public var trackLookupPrefix: String?
    /// Returns whether the participant has video.
    public var hasVideo: Bool
    /// Returns whether the participant has audio.
    public var hasAudio: Bool
    /// Returns whether the participant is screen sharing.
    public var isScreensharing: Bool
    /// Returns the participant's video track.
    public var track: RTCVideoTrack?
    /// Returns the size of the track for the participant.
    public var trackSize: CGSize
    /// Returns the screensharing track for the participant.
    public var screenshareTrack: RTCVideoTrack?
    /// Returns whether the track should be shown.
    public var showTrack: Bool
    /// Returns whether the participant is speaking.
    public var isSpeaking: Bool
    /// Returns whether the participant is a dominant speaker.
    public var isDominantSpeaker: Bool
    /// Returns the session id of the participant.
    public var sessionId: String
    /// The participant's connection quality.
    public var connectionQuality: ConnectionQuality
    /// Returns the date when the user joined the call.
    public var joinedAt: Date
    /// The audio level for the user.
    public var audioLevel: Float
    /// List of the last 10 audio levels.
    public var audioLevels: [Float]
    public var pin: PinInfo?
    
    public init(
        id: String,
        userId: String,
        roles: [String],
        name: String,
        profileImageURL: URL?,
        trackLookupPrefix: String?,
        hasVideo: Bool,
        hasAudio: Bool,
        isScreenSharing: Bool,
        showTrack: Bool,
        track: RTCVideoTrack? = nil,
        trackSize: CGSize = CGSize(width: 1024, height: 720),
        screenshareTrack: RTCVideoTrack? = nil,
        isSpeaking: Bool = false,
        isDominantSpeaker: Bool,
        sessionId: String,
        connectionQuality: ConnectionQuality,
        joinedAt: Date,
        audioLevel: Float,
        audioLevels: [Float],
        pin: PinInfo?
    ) {
        self.id = id
        self.userId = userId
        self.roles = roles
        self.name = name
        self.profileImageURL = profileImageURL
        self.trackLookupPrefix = trackLookupPrefix
        self.hasVideo = hasVideo
        self.hasAudio = hasAudio
        self.showTrack = showTrack
        self.track = track
        self.trackSize = trackSize
        self.isSpeaking = isSpeaking
        self.isDominantSpeaker = isDominantSpeaker
        self.sessionId = sessionId
        self.screenshareTrack = screenshareTrack
        self.connectionQuality = connectionQuality
        isScreensharing = isScreenSharing
        self.joinedAt = joinedAt
        self.audioLevel = audioLevel
        self.audioLevels = audioLevels
        self.pin = pin
    }
    
    public var isPinned: Bool {
        pin != nil
    }
    
    public var isPinnedRemotely: Bool {
        guard let pin else { return false }
        return pin.isLocal == false
    }
    
    /// Determines whether the track of the participant should be displayed.
    public var shouldDisplayTrack: Bool {
        hasVideo && track != nil && showTrack
    }
    
    public func withUpdated(trackSize: CGSize) -> CallParticipant {
        CallParticipant(
            id: id,
            userId: userId,
            roles: roles,
            name: name,
            profileImageURL: profileImageURL,
            trackLookupPrefix: trackLookupPrefix,
            hasVideo: hasVideo,
            hasAudio: hasAudio,
            isScreenSharing: isScreensharing,
            showTrack: showTrack,
            track: track,
            trackSize: trackSize,
            screenshareTrack: screenshareTrack,
            isSpeaking: isSpeaking,
            isDominantSpeaker: isDominantSpeaker,
            sessionId: sessionId,
            connectionQuality: connectionQuality,
            joinedAt: joinedAt,
            audioLevel: audioLevel,
            audioLevels: audioLevels,
            pin: pin
        )
    }
    
    public func withUpdated(track: RTCVideoTrack?) -> CallParticipant {
        CallParticipant(
            id: id,
            userId: userId,
            roles: roles,
            name: name,
            profileImageURL: profileImageURL,
            trackLookupPrefix: trackLookupPrefix,
            hasVideo: hasVideo,
            hasAudio: hasAudio,
            isScreenSharing: isScreensharing,
            showTrack: showTrack,
            track: track,
            trackSize: trackSize,
            screenshareTrack: screenshareTrack,
            isSpeaking: isSpeaking,
            isDominantSpeaker: isDominantSpeaker,
            sessionId: sessionId,
            connectionQuality: connectionQuality,
            joinedAt: joinedAt,
            audioLevel: audioLevel,
            audioLevels: audioLevels,
            pin: pin
        )
    }
    
    public func withUpdated(screensharingTrack: RTCVideoTrack?) -> CallParticipant {
        CallParticipant(
            id: id,
            userId: userId,
            roles: roles,
            name: name,
            profileImageURL: profileImageURL,
            trackLookupPrefix: trackLookupPrefix,
            hasVideo: hasVideo,
            hasAudio: hasAudio,
            isScreenSharing: isScreensharing,
            showTrack: showTrack,
            track: track,
            trackSize: trackSize,
            screenshareTrack: screensharingTrack,
            isSpeaking: isSpeaking,
            isDominantSpeaker: isDominantSpeaker,
            sessionId: sessionId,
            connectionQuality: connectionQuality,
            joinedAt: joinedAt,
            audioLevel: audioLevel,
            audioLevels: audioLevels,
            pin: pin
        )
    }
    
    public func withUpdated(audio: Bool) -> CallParticipant {
        CallParticipant(
            id: id,
            userId: userId,
            roles: roles,
            name: name,
            profileImageURL: profileImageURL,
            trackLookupPrefix: trackLookupPrefix,
            hasVideo: hasVideo,
            hasAudio: audio,
            isScreenSharing: isScreensharing,
            showTrack: showTrack,
            track: track,
            trackSize: trackSize,
            screenshareTrack: screenshareTrack,
            isSpeaking: isSpeaking,
            isDominantSpeaker: isDominantSpeaker,
            sessionId: sessionId,
            connectionQuality: connectionQuality,
            joinedAt: joinedAt,
            audioLevel: audioLevel,
            audioLevels: audioLevels,
            pin: pin
        )
    }

    public func withUpdated(video: Bool) -> CallParticipant {
        CallParticipant(
            id: id,
            userId: userId,
            roles: roles,
            name: name,
            profileImageURL: profileImageURL,
            trackLookupPrefix: trackLookupPrefix,
            hasVideo: video,
            hasAudio: hasAudio,
            isScreenSharing: isScreensharing,
            showTrack: showTrack,
            track: track,
            trackSize: trackSize,
            screenshareTrack: screenshareTrack,
            isSpeaking: isSpeaking,
            isDominantSpeaker: isDominantSpeaker,
            sessionId: sessionId,
            connectionQuality: connectionQuality,
            joinedAt: joinedAt,
            audioLevel: audioLevel,
            audioLevels: audioLevels,
            pin: pin
        )
    }
    
    public func withUpdated(screensharing: Bool) -> CallParticipant {
        CallParticipant(
            id: id,
            userId: userId,
            roles: roles,
            name: name,
            profileImageURL: profileImageURL,
            trackLookupPrefix: trackLookupPrefix,
            hasVideo: hasVideo,
            hasAudio: hasAudio,
            isScreenSharing: screensharing,
            showTrack: showTrack,
            track: track,
            trackSize: trackSize,
            screenshareTrack: screenshareTrack,
            isSpeaking: isSpeaking,
            isDominantSpeaker: isDominantSpeaker,
            sessionId: sessionId,
            connectionQuality: connectionQuality,
            joinedAt: joinedAt,
            audioLevel: audioLevel,
            audioLevels: audioLevels,
            pin: pin
        )
    }

    public func withUpdated(showTrack: Bool) -> CallParticipant {
        CallParticipant(
            id: id,
            userId: userId,
            roles: roles,
            name: name,
            profileImageURL: profileImageURL,
            trackLookupPrefix: trackLookupPrefix,
            hasVideo: hasVideo,
            hasAudio: hasAudio,
            isScreenSharing: isScreensharing,
            showTrack: showTrack,
            track: track,
            trackSize: trackSize,
            screenshareTrack: screenshareTrack,
            isSpeaking: isSpeaking,
            isDominantSpeaker: isDominantSpeaker,
            sessionId: sessionId,
            connectionQuality: connectionQuality,
            joinedAt: joinedAt,
            audioLevel: audioLevel,
            audioLevels: audioLevels,
            pin: pin
        )
    }

    public func withUpdated(
        isSpeaking: Bool,
        audioLevel: Float
    ) -> CallParticipant {
        var levels = audioLevels
        levels.append(audioLevel)
        let limit = 10
        if levels.count > limit {
            levels = Array(levels.dropFirst(levels.count - limit))
        }
        return CallParticipant(
            id: id,
            userId: userId,
            roles: roles,
            name: name,
            profileImageURL: profileImageURL,
            trackLookupPrefix: trackLookupPrefix,
            hasVideo: hasVideo,
            hasAudio: hasAudio,
            isScreenSharing: isScreensharing,
            showTrack: showTrack,
            track: track,
            trackSize: trackSize,
            screenshareTrack: screenshareTrack,
            isSpeaking: isSpeaking,
            isDominantSpeaker: isDominantSpeaker,
            sessionId: sessionId,
            connectionQuality: connectionQuality,
            joinedAt: joinedAt,
            audioLevel: audioLevel,
            audioLevels: audioLevels,
            pin: pin
        )
    }
    
    public func withUpdated(dominantSpeaker: Bool) -> CallParticipant {
        CallParticipant(
            id: id,
            userId: userId,
            roles: roles,
            name: name,
            profileImageURL: profileImageURL,
            trackLookupPrefix: trackLookupPrefix,
            hasVideo: hasVideo,
            hasAudio: hasAudio,
            isScreenSharing: isScreensharing,
            showTrack: showTrack,
            track: track,
            trackSize: trackSize,
            screenshareTrack: screenshareTrack,
            isSpeaking: isSpeaking,
            isDominantSpeaker: dominantSpeaker,
            sessionId: sessionId,
            connectionQuality: connectionQuality,
            joinedAt: joinedAt,
            audioLevel: audioLevel,
            audioLevels: audioLevels,
            pin: pin
        )
    }
    
    public func withUpdated(connectionQuality: ConnectionQuality) -> CallParticipant {
        CallParticipant(
            id: id,
            userId: userId,
            roles: roles,
            name: name,
            profileImageURL: profileImageURL,
            trackLookupPrefix: trackLookupPrefix,
            hasVideo: hasVideo,
            hasAudio: hasAudio,
            isScreenSharing: isScreensharing,
            showTrack: showTrack,
            track: track,
            trackSize: trackSize,
            screenshareTrack: screenshareTrack,
            isSpeaking: isSpeaking,
            isDominantSpeaker: isDominantSpeaker,
            sessionId: sessionId,
            connectionQuality: connectionQuality,
            joinedAt: joinedAt,
            audioLevel: audioLevel,
            audioLevels: audioLevels,
            pin: pin
        )
    }
    
    public func withUpdated(pin: PinInfo?) -> CallParticipant {
        CallParticipant(
            id: id,
            userId: userId,
            roles: roles,
            name: name,
            profileImageURL: profileImageURL,
            trackLookupPrefix: trackLookupPrefix,
            hasVideo: hasVideo,
            hasAudio: hasAudio,
            isScreenSharing: isScreensharing,
            showTrack: showTrack,
            track: track,
            trackSize: trackSize,
            screenshareTrack: screenshareTrack,
            isSpeaking: isSpeaking,
            isDominantSpeaker: isDominantSpeaker,
            sessionId: sessionId,
            connectionQuality: connectionQuality,
            joinedAt: joinedAt,
            audioLevel: audioLevel,
            audioLevels: audioLevels,
            pin: pin
        )
    }
}

extension Stream_Video_Sfu_Models_Participant {
    
    func toCallParticipant(showTrack: Bool = true, pin: PinInfo? = nil) -> CallParticipant {
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
            pin: pin
        )
    }
}

public struct PinInfo: Sendable, Equatable {
    public let isLocal: Bool
    public let pinnedAt: Date
}
