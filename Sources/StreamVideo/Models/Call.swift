//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import AVFoundation
import SwiftUI

/// Represents a call that's in progress.
public class Call: ObservableObject, @unchecked Sendable {
            
    /// The current participants dictionary.
    @Published public internal(set) var participants = [String: CallParticipant]() {
        didSet {
            log.debug("Participants changed: \(participants)")
        }
    }
    
    public let callId: String
    public let callType: CallType
    public let sessionId: String
    
    var onParticipantEvent: ((ParticipantEvent) -> Void)?
    
    private let syncQueue = DispatchQueue(label: "io.getstream.CallQueue", qos: .userInitiated)
    
    static func create(callId: String, callType: CallType, sessionId: String) -> Call {
        Call(callId: callId, callType: callType, sessionId: sessionId)
    }
    
    private init(callId: String, callType: CallType, sessionId: String) {
        self.callId = callId
        self.callType = callType
        self.sessionId = sessionId
    }
    
    /// Async stream that publishes participant events.
    public func participantEvents() -> AsyncStream<ParticipantEvent> {
        let events = AsyncStream(ParticipantEvent.self) { [weak self] continuation in
            self?.onParticipantEvent = { event in
                continuation.yield(event)
            }
        }
        return events
    }
    
    // MARK: - internal
    
    func add(participants: [CallParticipant]) {
        syncQueue.async { [weak self] in
            guard let self = self else { return }
            var result = [String: CallParticipant]()
            for participant in participants {
                let track = self.participants[participant.id]?.track
                let updated = participant.withUpdated(track: track)
                result[participant.id] = updated
            }
            self.participants = result
        }
    }
    
    func clearParticipants() {
        syncQueue.async { [weak self] in
            guard let self = self else { return }
            self.participants = [:]
        }
    }
    
    func add(participant: CallParticipant) {
        syncQueue.async { [weak self] in
            guard let self = self else { return }
            let track = self.participants[participant.id]?.track
            let updated = participant.withUpdated(track: track)
            self.participants[participant.id] = updated
        }
    }
    
    func removeParticipant(with id: String) {
        syncQueue.async { [weak self] in
            guard let self = self else { return }
            self.participants[id] = nil
        }
    }
    
    func remove(participant: CallParticipant) {
        syncQueue.async { [weak self] in
            guard let self = self else { return }
            self.participants[participant.id] = nil
        }
    }
    
    func handleParticipantEvent(_ eventType: CallEventType, for participantId: String) {
        syncQueue.async { [weak self] in
            guard let self = self,
                  let participant = self.participants[participantId] else {
                return
            }
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
            self.participants[participantId] = updated
        }
    }
}

enum CallEventType {
    case videoStarted
    case videoStopped
    case audioStarted
    case audioStopped
}

/// Represents a participant event during a call.
public struct ParticipantEvent: Sendable {
    public let id: String
    public let action: ParticipantAction
    public let user: String
    public let imageURL: URL?
}

/// Represents a participant action (joining / leaving a call).
public enum ParticipantAction: Sendable {
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
