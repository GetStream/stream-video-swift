//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import AVFoundation
import SwiftUI

public class Room: ObservableObject {
            
    @Published var participants = [String: CallParticipant]() {
        didSet {
            log.debug("Participants changed: \(participants)")
        }
    }
    
    var onParticipantEvent: ((ParticipantEvent) -> Void)?
    
    static func create() -> Room {
        Room()
    }
    
    private init() {}
    
    func add(participants: [CallParticipant]) {
        var result = [String: CallParticipant]()
        for participant in participants {
            let track = self.participants[participant.id]?.track
            participant.track = track
            result[participant.id] = participant
        }
        self.participants = result
    }
    
    func clearParticipants() {
        participants = [:]
    }
    
    func add(participant: CallParticipant) {
        let track = participants[participant.id]?.track
        participant.track = track
        participants[participant.id] = participant
    }
    
    func removeParticipant(with id: String) {
        participants[id] = nil
    }
    
    func remove(participant: CallParticipant) {
        participants[participant.id] = nil
    }
    
    func handleParticipantEvent(_ eventType: CallEventType, for participantId: String) {
        guard let participant = participants[participantId] else { return }
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
}

public struct VideoOptions {
    // TODO:
    public init() {}
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
