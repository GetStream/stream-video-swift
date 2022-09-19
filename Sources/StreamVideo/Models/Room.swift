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
            let updated = participant.withUpdated(track: track)
            result[participant.id] = updated
        }
        self.participants = result
    }
    
    func clearParticipants() {
        participants = [:]
    }
    
    func add(participant: CallParticipant) {
        let track = participants[participant.id]?.track
        let updated = participant.withUpdated(track: track)
        participants[participant.id] = updated
    }
    
    func removeParticipant(with id: String) {
        participants[id] = nil
    }
    
    func remove(participant: CallParticipant) {
        participants[participant.id] = nil
    }
    
    func handleParticipantEvent(_ eventType: CallEventType, for participantId: String) {
        guard let participant = participants[participantId] else { return }
        let updated: CallParticipant
        switch eventType {
        case .videoStarted:
            updated = participant.withUpdated(video: true)
        case .videoStopped:
            updated = participant.withUpdated(video: false)
        case .audioStarted:
            updated = participant.withUpdated(audio: true)
        case .audioStopped:
            updated = participant.withUpdated(audio: false)
        }
        participants[participantId] = updated
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
