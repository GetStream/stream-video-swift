//
//  RoomParticipant.swift
//  StreamVideoSwiftUI
//
//  Created by Martin Mitrevski on 8.7.22.
//

import Foundation
import LiveKit

class RoomParticipant {
    private let participant: Participant
    
    var id: String {
        self.participant.sid
    }
    
    var name: String {
        self.participant.name
    }
    
    init(participant: Participant) {
        self.participant = participant
    }
    
    public var connectionQuality: VideoConnectionQuality {
        self.participant.connectionQuality
    }
    
    public var isSpeaking: Bool {
        self.participant.isSpeaking
    }
    
    public var firstCameraPublication: VideoTrackPublication? {
        participant.videoTracks.first(where: { $0.source == .camera })
    }

    public var firstScreenSharePublication: VideoTrackPublication? {
        participant.videoTracks.first(where: { $0.source == .screenShareVideo })
    }

    public var firstAudioPublication: VideoTrackPublication? {
        participant.audioTracks.first
    }
    
    public var firstCameraVideoTrack: StreamVideoTrack? {
        guard let pub = firstCameraPublication, !pub.muted, pub.subscribed,
              let track = pub.track else { return nil }
        return track as? VideoTrack
    }

    public var firstScreenShareVideoTrack: StreamVideoTrack? {
        guard let pub = firstScreenSharePublication, !pub.muted, pub.subscribed,
              let track = pub.track else { return nil }
        return track as? VideoTrack
    }
    
}

extension RoomParticipant {

    public var mainVideoPublication: VideoTrackPublication? {
        firstScreenSharePublication ?? firstCameraPublication
    }

    public var mainVideoTrack: StreamVideoTrack? {
        firstScreenShareVideoTrack ?? firstCameraVideoTrack
    }

    public var subVideoTrack: StreamVideoTrack? {
        firstScreenShareVideoTrack != nil ? firstCameraVideoTrack : nil
    }
}
