//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@preconcurrency import WebRTC

/// Represents a participant in the call.
public struct CallParticipant: Identifiable, Sendable {
    public var id: String
    public let role: String
    public let name: String
    public let profileImageURL: URL?
    public var trackLookupPrefix: String?
    public var isOnline: Bool
    public var hasVideo: Bool
    public var hasAudio: Bool
    public var track: RTCVideoTrack?
    public var trackSize: CGSize
    public var showTrack: Bool
    public var layoutPriority: LayoutPriority
    public var isDominantSpeaker: Bool
    
    public init(
        id: String,
        role: String,
        name: String,
        profileImageURL: URL?,
        trackLookupPrefix: String?,
        isOnline: Bool,
        hasVideo: Bool,
        hasAudio: Bool,
        showTrack: Bool,
        track: RTCVideoTrack? = nil,
        trackSize: CGSize = .zero,
        layoutPriority: LayoutPriority = .normal,
        isDominantSpeaker: Bool = false
    ) {
        self.id = id
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
        self.isDominantSpeaker = isDominantSpeaker
    }
    
    /// Determines whether the track of the participant should be displayed.
    public var shouldDisplayTrack: Bool {
        hasVideo && track != nil && showTrack
    }
    
    public func withUpdated(trackSize: CGSize) -> CallParticipant {
        CallParticipant(
            id: id,
            role: role,
            name: name,
            profileImageURL: profileImageURL,
            trackLookupPrefix: trackLookupPrefix,
            isOnline: isOnline,
            hasVideo: hasVideo,
            hasAudio: hasAudio,
            showTrack: showTrack,
            track: track,
            trackSize: trackSize,
            layoutPriority: layoutPriority,
            isDominantSpeaker: isDominantSpeaker
        )
    }
    
    func withUpdated(track: RTCVideoTrack?) -> CallParticipant {
        CallParticipant(
            id: id,
            role: role,
            name: name,
            profileImageURL: profileImageURL,
            trackLookupPrefix: trackLookupPrefix,
            isOnline: isOnline,
            hasVideo: hasVideo,
            hasAudio: hasAudio,
            showTrack: showTrack,
            track: track,
            trackSize: trackSize,
            layoutPriority: layoutPriority,
            isDominantSpeaker: isDominantSpeaker
        )
    }
    
    func withUpdated(audio: Bool) -> CallParticipant {
        CallParticipant(
            id: id,
            role: role,
            name: name,
            profileImageURL: profileImageURL,
            trackLookupPrefix: trackLookupPrefix,
            isOnline: isOnline,
            hasVideo: hasVideo,
            hasAudio: audio,
            showTrack: showTrack,
            track: track,
            trackSize: trackSize,
            layoutPriority: layoutPriority,
            isDominantSpeaker: isDominantSpeaker
        )
    }

    func withUpdated(video: Bool) -> CallParticipant {
        CallParticipant(
            id: id,
            role: role,
            name: name,
            profileImageURL: profileImageURL,
            trackLookupPrefix: trackLookupPrefix,
            isOnline: isOnline,
            hasVideo: video,
            hasAudio: hasAudio,
            showTrack: showTrack,
            track: track,
            trackSize: trackSize,
            layoutPriority: layoutPriority,
            isDominantSpeaker: isDominantSpeaker
        )
    }

    func withUpdated(showTrack: Bool) -> CallParticipant {
        CallParticipant(
            id: id,
            role: role,
            name: name,
            profileImageURL: profileImageURL,
            trackLookupPrefix: trackLookupPrefix,
            isOnline: isOnline,
            hasVideo: hasVideo,
            hasAudio: hasAudio,
            showTrack: showTrack,
            track: track,
            trackSize: trackSize,
            layoutPriority: layoutPriority,
            isDominantSpeaker: isDominantSpeaker
        )
    }

    func withUpdated(
        layoutPriority: LayoutPriority,
        isDominantSpeaker: Bool
    ) -> CallParticipant {
        CallParticipant(
            id: id,
            role: role,
            name: name,
            profileImageURL: profileImageURL,
            trackLookupPrefix: trackLookupPrefix,
            isOnline: isOnline,
            hasVideo: hasVideo,
            hasAudio: hasAudio,
            showTrack: showTrack,
            track: track,
            trackSize: trackSize,
            layoutPriority: layoutPriority
        )
    }
}

public enum LayoutPriority: Int, Sendable {
    case high = 1
    case normal = 5
    case low = 10
}

extension CallParticipant {
    
    public func toUserInfo() -> UserInfo {
        UserInfo(
            id: id,
            name: name,
            imageURL: profileImageURL,
            extraData: [:]
        )
    }
}

extension Stream_Video_Participant {
    
    func toCallParticipant() -> CallParticipant {
        CallParticipant(
            id: user.id,
            role: role,
            name: user.name.isEmpty ? user.id : user.name,
            profileImageURL: URL(string: user.imageURL),
            trackLookupPrefix: nil,
            isOnline: online,
            hasVideo: video,
            hasAudio: audio,
            showTrack: true
        )
    }
}

extension Stream_Video_User {
    
    func toCallParticipant() -> CallParticipant {
        CallParticipant(
            id: id,
            role: role,
            name: name.isEmpty ? id : name,
            profileImageURL: URL(string: imageURL),
            trackLookupPrefix: nil,
            isOnline: false,
            hasVideo: false,
            hasAudio: false,
            showTrack: false
        )
    }
}

extension Stream_Video_Sfu_Models_Participant {
    
    func toCallParticipant(showTrack: Bool = true) -> CallParticipant {
        CallParticipant(
            id: user.id,
            role: role,
            name: user.name.isEmpty ? user.id : user.name,
            profileImageURL: URL(string: user.imageURL),
            trackLookupPrefix: trackLookupPrefix,
            isOnline: online,
            hasVideo: video,
            hasAudio: audio,
            showTrack: showTrack
        )
    }
}

extension Stream_Video_JoinCallResponse {
    
    func callParticipants() -> [CallParticipant] {
        call.users.map { (_, participant) in
            participant.toCallParticipant()
        }
    }
}
