//
//  CallParticipant.swift
//  StreamVideo
//
//  Created by Martin Mitrevski on 27.7.22.
//

import Foundation

public struct CallParticipant: Identifiable {
    public let id: String
    public let role: String
    public let name: String
    public let profileImageURL: URL?
    public var isOnline: Bool
    public var hasVideo: Bool
    public var hasAudio: Bool
}

extension Stream_Video_Participant {
    
    func toCallParticipant() -> CallParticipant {
        CallParticipant(
            id: self.user.id,
            role: self.role,
            name: self.user.name.isEmpty ? self.user.id : self.user.name,
            profileImageURL: URL(string: self.user.imageURL),
            isOnline: self.online,
            hasVideo: self.video,
            hasAudio: self.audio
        )
    }
    
}

extension Stream_Video_JoinCallResponse {
    
    func callParticipants() -> [CallParticipant] {
        callState.participants.map { $0.toCallParticipant() }
    }
    
}
