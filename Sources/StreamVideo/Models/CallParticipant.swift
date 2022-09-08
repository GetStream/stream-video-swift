//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import WebRTC

public class CallParticipant: Identifiable {
    public let id: String
    public let role: String
    public let name: String
    public let profileImageURL: URL?
    public var isOnline: Bool
    public var hasVideo: Bool
    public var hasAudio: Bool
    public var track: RTCVideoTrack?
    public var trackSize: CGSize = .zero
    public var showTrack: Bool
    public var layoutPriority = LayoutPriority.normal
    public var isDominantSpeaker = false
    
    public init(
        id: String,
        role: String,
        name: String,
        profileImageURL: URL?,
        isOnline: Bool,
        hasVideo: Bool,
        hasAudio: Bool,
        showTrack: Bool
    ) {
        self.id = id
        self.role = role
        self.name = name
        self.profileImageURL = profileImageURL
        self.isOnline = isOnline
        self.hasVideo = hasVideo
        self.hasAudio = hasAudio
        self.showTrack = true
    }
    
    public var shouldDisplayTrack: Bool {
        hasVideo && track != nil && showTrack
    }
}

public enum LayoutPriority: Int {
    case high = 1
    case normal = 5
    case low = 10
}

extension Stream_Video_Participant {
    
    func toCallParticipant() -> CallParticipant {
        CallParticipant(
            id: user.id,
            role: role,
            name: user.name.isEmpty ? user.id : user.name,
            profileImageURL: URL(string: user.imageURL),
            isOnline: online,
            hasVideo: video,
            hasAudio: audio,
            showTrack: true
        )
    }
}

extension Stream_Video_Sfu_Participant {
    
    func toCallParticipant(showTrack: Bool = true) -> CallParticipant {
        CallParticipant(
            id: user.id,
            role: role,
            name: user.name.isEmpty ? user.id : user.name,
            profileImageURL: URL(string: user.imageURL),
            isOnline: online,
            hasVideo: video,
            hasAudio: audio,
            showTrack: showTrack
        )
    }
}

extension Stream_Video_JoinCallResponse {
    
    func callParticipants() -> [CallParticipant] {
        callState.participants.map { $0.toCallParticipant() }
    }
}
