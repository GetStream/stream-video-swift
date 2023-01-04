//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
@preconcurrency import WebRTC

/// Represents a participant in the call.
public struct CallParticipant: Identifiable, Sendable {
    public var id: String
    public let userId: String
    public let role: String
    public let name: String
    public let profileImageURL: URL?
    public var trackLookupPrefix: String?
    public var isOnline: Bool
    public var hasVideo: Bool
    public var hasAudio: Bool
    public var isScreensharing: Bool
    public var track: RTCVideoTrack?
    public var trackSize: CGSize
    public var screenshareTrack: RTCVideoTrack?
    public var showTrack: Bool
    public var layoutPriority: LayoutPriority
    public var isSpeaking: Bool
    public var sessionId: String
    public var connectionQuality: ConnectionQuality
    
    public init(
        id: String,
        userId: String,
        role: String,
        name: String,
        profileImageURL: URL?,
        trackLookupPrefix: String?,
        isOnline: Bool,
        hasVideo: Bool,
        hasAudio: Bool,
        isScreenSharing: Bool,
        showTrack: Bool,
        track: RTCVideoTrack? = nil,
        trackSize: CGSize = CGSize(width: 1024, height: 720),
        screenshareTrack: RTCVideoTrack? = nil,
        layoutPriority: LayoutPriority = .normal,
        isSpeaking: Bool = false,
        sessionId: String,
        connectionQuality: ConnectionQuality
    ) {
        self.id = id
        self.userId = userId
        self.role = role
        self.name = name
        self.profileImageURL = profileImageURL
        self.trackLookupPrefix = trackLookupPrefix
        self.isOnline = isOnline
        self.hasVideo = hasVideo
        self.hasAudio = hasAudio
        self.showTrack = showTrack
        self.track = track
        self.trackSize = trackSize
        self.layoutPriority = layoutPriority
        self.isSpeaking = isSpeaking
        self.sessionId = sessionId
        self.screenshareTrack = screenshareTrack
        self.connectionQuality = connectionQuality
        isScreensharing = isScreenSharing
    }
    
    /// Determines whether the track of the participant should be displayed.
    public var shouldDisplayTrack: Bool {
        hasVideo && track != nil && showTrack
    }
    
    public func withUpdated(trackSize: CGSize) -> CallParticipant {
        CallParticipant(
            id: id,
            userId: userId,
            role: role,
            name: name,
            profileImageURL: profileImageURL,
            trackLookupPrefix: trackLookupPrefix,
            isOnline: isOnline,
            hasVideo: hasVideo,
            hasAudio: hasAudio,
            isScreenSharing: isScreensharing,
            showTrack: showTrack,
            track: track,
            trackSize: trackSize,
            screenshareTrack: screenshareTrack,
            layoutPriority: layoutPriority,
            isSpeaking: isSpeaking,
            sessionId: sessionId,
            connectionQuality: connectionQuality
        )
    }
    
    func withUpdated(track: RTCVideoTrack?) -> CallParticipant {
        CallParticipant(
            id: id,
            userId: userId,
            role: role,
            name: name,
            profileImageURL: profileImageURL,
            trackLookupPrefix: trackLookupPrefix,
            isOnline: isOnline,
            hasVideo: hasVideo,
            hasAudio: hasAudio,
            isScreenSharing: isScreensharing,
            showTrack: showTrack,
            track: track,
            trackSize: trackSize,
            screenshareTrack: screenshareTrack,
            layoutPriority: layoutPriority,
            isSpeaking: isSpeaking,
            sessionId: sessionId,
            connectionQuality: connectionQuality
        )
    }
    
    func withUpdated(screensharingTrack: RTCVideoTrack?) -> CallParticipant {
        CallParticipant(
            id: id,
            userId: userId,
            role: role,
            name: name,
            profileImageURL: profileImageURL,
            trackLookupPrefix: trackLookupPrefix,
            isOnline: isOnline,
            hasVideo: hasVideo,
            hasAudio: hasAudio,
            isScreenSharing: isScreensharing,
            showTrack: showTrack,
            track: track,
            trackSize: trackSize,
            screenshareTrack: screensharingTrack,
            layoutPriority: layoutPriority,
            isSpeaking: isSpeaking,
            sessionId: sessionId,
            connectionQuality: connectionQuality
        )
    }
    
    func withUpdated(audio: Bool) -> CallParticipant {
        CallParticipant(
            id: id,
            userId: userId,
            role: role,
            name: name,
            profileImageURL: profileImageURL,
            trackLookupPrefix: trackLookupPrefix,
            isOnline: isOnline,
            hasVideo: hasVideo,
            hasAudio: audio,
            isScreenSharing: isScreensharing,
            showTrack: showTrack,
            track: track,
            trackSize: trackSize,
            screenshareTrack: screenshareTrack,
            layoutPriority: layoutPriority,
            isSpeaking: isSpeaking,
            sessionId: sessionId,
            connectionQuality: connectionQuality
        )
    }

    func withUpdated(video: Bool) -> CallParticipant {
        CallParticipant(
            id: id,
            userId: userId,
            role: role,
            name: name,
            profileImageURL: profileImageURL,
            trackLookupPrefix: trackLookupPrefix,
            isOnline: isOnline,
            hasVideo: video,
            hasAudio: hasAudio,
            isScreenSharing: isScreensharing,
            showTrack: showTrack,
            track: track,
            trackSize: trackSize,
            screenshareTrack: screenshareTrack,
            layoutPriority: layoutPriority,
            isSpeaking: isSpeaking,
            sessionId: sessionId,
            connectionQuality: connectionQuality
        )
    }
    
    func withUpdated(screensharing: Bool) -> CallParticipant {
        CallParticipant(
            id: id,
            userId: userId,
            role: role,
            name: name,
            profileImageURL: profileImageURL,
            trackLookupPrefix: trackLookupPrefix,
            isOnline: isOnline,
            hasVideo: hasVideo,
            hasAudio: hasAudio,
            isScreenSharing: screensharing,
            showTrack: showTrack,
            track: track,
            trackSize: trackSize,
            screenshareTrack: screenshareTrack,
            layoutPriority: layoutPriority,
            isSpeaking: isSpeaking,
            sessionId: sessionId,
            connectionQuality: connectionQuality
        )
    }

    func withUpdated(showTrack: Bool) -> CallParticipant {
        CallParticipant(
            id: id,
            userId: userId,
            role: role,
            name: name,
            profileImageURL: profileImageURL,
            trackLookupPrefix: trackLookupPrefix,
            isOnline: isOnline,
            hasVideo: hasVideo,
            hasAudio: hasAudio,
            isScreenSharing: isScreensharing,
            showTrack: showTrack,
            track: track,
            trackSize: trackSize,
            screenshareTrack: screenshareTrack,
            layoutPriority: layoutPriority,
            isSpeaking: isSpeaking,
            sessionId: sessionId,
            connectionQuality: connectionQuality
        )
    }

    func withUpdated(
        layoutPriority: LayoutPriority,
        isSpeaking: Bool
    ) -> CallParticipant {
        CallParticipant(
            id: id,
            userId: userId,
            role: role,
            name: name,
            profileImageURL: profileImageURL,
            trackLookupPrefix: trackLookupPrefix,
            isOnline: isOnline,
            hasVideo: hasVideo,
            hasAudio: hasAudio,
            isScreenSharing: isScreensharing,
            showTrack: showTrack,
            track: track,
            trackSize: trackSize,
            screenshareTrack: screenshareTrack,
            layoutPriority: layoutPriority,
            isSpeaking: isSpeaking,
            sessionId: sessionId,
            connectionQuality: connectionQuality
        )
    }
    
    func withUpdated(connectionQuality: ConnectionQuality) -> CallParticipant {
        CallParticipant(
            id: id,
            userId: userId,
            role: role,
            name: name,
            profileImageURL: profileImageURL,
            trackLookupPrefix: trackLookupPrefix,
            isOnline: isOnline,
            hasVideo: hasVideo,
            hasAudio: hasAudio,
            isScreenSharing: isScreensharing,
            showTrack: showTrack,
            track: track,
            trackSize: trackSize,
            screenshareTrack: screenshareTrack,
            layoutPriority: layoutPriority,
            isSpeaking: isSpeaking,
            sessionId: sessionId,
            connectionQuality: connectionQuality
        )
    }
}

public enum LayoutPriority: Int, Sendable {
    case high = 1
    case normal = 5
    case low = 10
}

extension CallParticipant {
    
    public func toUser() -> User {
        User(
            id: id,
            name: name,
            imageURL: profileImageURL,
            extraData: [:]
        )
    }
}

extension Stream_Video_User {
    
    func toCallParticipant() -> CallParticipant {
        CallParticipant(
            id: id,
            userId: id,
            role: role,
            name: name.isEmpty ? id : name,
            profileImageURL: URL(string: imageURL),
            trackLookupPrefix: nil,
            isOnline: false,
            hasVideo: false,
            hasAudio: false,
            isScreenSharing: false,
            showTrack: false,
            sessionId: "",
            connectionQuality: .unknown
        )
    }
}

extension Stream_Video_Sfu_Models_Participant {
    
    func toCallParticipant(showTrack: Bool = true, enrichData: EnrichedUserData) -> CallParticipant {
        CallParticipant(
            id: sessionID,
            userId: userID,
            role: enrichData.role,
            name: enrichData.name,
            profileImageURL: enrichData.imageUrl,
            trackLookupPrefix: trackLookupPrefix,
            isOnline: true, // TODO: handle this
            hasVideo: publishedTracks.contains(where: { $0 == .video }),
            hasAudio: publishedTracks.contains(where: { $0 == .audio }),
            isScreenSharing: publishedTracks.contains(where: { $0 == .screenShare }),
            showTrack: showTrack,
            sessionId: sessionID,
            connectionQuality: connectionQuality.mapped
        )
    }
}
