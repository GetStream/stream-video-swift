//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import SwiftUI
import LiveKit
import AVFoundation

public class VideoRoom: ObservableObject {
        
    private let room: Room
    
    @Published var participants = [String: CallParticipant]() {
        didSet {
            log.debug("Participants changed: \(participants)")
        }
    }
    
    var onParticipantEvent: ((ParticipantEvent) -> ())?
    
    static func create(with room: Room) -> VideoRoom {
        return VideoRoom(room: room)
    }
    
    private init(room: Room) {
        self.room = room
    }
    
    func addDelegate(_ delegate: VideoRoomDelegate) {
        self.room.add(delegate: delegate)
    }
    
    func disconnect() {
        self.room.disconnect()
    }
    
    func add(participants: [CallParticipant]) {
        var result = [String: CallParticipant]()
        for participant in participants {
            result[participant.id] = participant
        }
        self.participants = result
    }
    
    func clearParticipants() {
        self.participants = [:]
    }
    
    func add(participant: CallParticipant) {
        participants[participant.id] = participant
    }
    
    func remove(participant: CallParticipant) {
        participants[participant.id] = nil
    }
    
    func handleParticipantEvent(_ eventType: CallEventType, for participantId: String) {
        guard var participant = participants[participantId] else { return }
        switch eventType {
        case .videoStarted:
            participant.hasVideo = true
        case .videoStopped:
            participant.hasVideo = false
        case .audioStarted:
            participant.hasAudio = true
        case .audioStopped:
            participant.hasAudio = false
        }
        participants[participantId] = participant
    }
    
    public func participantEvents() -> AsyncStream<ParticipantEvent> {
        let events = AsyncStream(ParticipantEvent.self) { [weak self] continuation in
            self?.onParticipantEvent = { event in
                continuation.yield(event)
            }
        }
        return events
    }
    
    internal var remoteParticipants: [Sid : RemoteParticipant] {
        self.room.remoteParticipants
    }
    
    internal var localParticipant: LocalParticipant? {
        self.room.localParticipant
    }
    
    internal var connectionStatus: VideoConnectionStatus {
        self.room.connectionState.mapped
    }
}

typealias VideoRoomDelegate = RoomDelegate

public struct VideoOptions {
    //TODO:
}

enum CallEventType {
    case videoStarted
    case videoStopped
    case audioStarted
    case audioStopped
}

public struct ParticipantEvent {
    public let id: String
    public let action: ParticipantAction
    public let user: String
    public let imageURL: URL?
}

public enum ParticipantAction {
    case join
    case leave
    
    public var display: String {
        switch self {
        case .leave:
            return "left"
        case .join:
            return "joined"
        }
    }
}
