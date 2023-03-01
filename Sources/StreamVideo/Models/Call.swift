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
    @Published public private(set) var blockedUsers: [User]
    
    public let callId: String
    public let callType: CallType
    public let sessionId: String
    
    var onParticipantEvent: ((ParticipantEvent) -> Void)?
    
    private let syncQueue = DispatchQueue(label: "io.getstream.CallQueue", qos: .userInitiated)
    
    static func create(callId: String, callType: CallType, sessionId: String, blockedUsers: [User]) -> Call {
        Call(callId: callId, callType: callType, sessionId: sessionId, blockedUsers: blockedUsers)
    }
    
    private init(callId: String, callType: CallType, sessionId: String, blockedUsers: [User]) {
        self.callId = callId
        self.callType = callType
        self.sessionId = sessionId
        self.blockedUsers = blockedUsers
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
    
    public func add(blockedUser: User) {
        blockedUsers.append(blockedUser)
    }
    
    public func remove(blockedUser: User) {
        blockedUsers.removeAll { user in
            user.id == blockedUser.id
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
