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
    /// The call info published to the participants.
    @Published public private(set) var callInfo: CallInfo
    /// Flag indicating if the call is reconnecting.
    @Published public private(set) var reconnecting = false
    /// The call recording state.
    @Published public private(set) var recordingState: RecordingState
    
    /// The call id.
    public let callId: String
    /// The type of the call.
    public let callType: CallType
    /// The id of the current session.
    public let sessionId: String
    
    /// The unique identifier of the call, formatted as `callType.name:callId`.
    public var cId: String {
        "\(callType.name):\(callId)"
    }
    
    /// The closure that handles the participant events.
    var onParticipantEvent: ((ParticipantEvent) -> Void)?
    
    private let syncQueue = DispatchQueue(label: "io.getstream.CallQueue", qos: .userInitiated)
    
    /// Creates a new instance of the `Call` class.
    /// - Parameters:
    ///   - callId: The unique identifier of the call.
    ///   - callType: The type of the call.
    ///   - sessionId: The session identifier of the call.
    ///   - callInfo: The call information published to the participants.
    ///   - recordingState: The current state of the call recording.
    /// - Returns: A new instance of the `Call` class.
    static func create(
        callId: String,
        callType: CallType,
        sessionId: String,
        callInfo: CallInfo,
        recordingState: RecordingState
    ) -> Call {
        Call(
            callId: callId,
            callType: callType,
            sessionId: sessionId,
            callInfo: callInfo,
            recordingState: recordingState
        )
    }
    
    private init(
        callId: String,
        callType: CallType,
        sessionId: String,
        callInfo: CallInfo,
        recordingState: RecordingState
    ) {
        self.callId = callId
        self.callType = callType
        self.sessionId = sessionId
        self.callInfo = callInfo
        self.recordingState = recordingState
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
    
    /// Adds the given user to the list of blocked users for the call.
    /// - Parameter blockedUser: The user to add to the list of blocked users.
    public func add(blockedUser: User) {
        var blockedUsers = callInfo.blockedUsers
        if !blockedUsers.contains(blockedUser) {
            blockedUsers.append(blockedUser)
            callInfo.blockedUsers = blockedUsers
        }
    }
    
    /// Removes the given user from the list of blocked users for the call.
    /// - Parameter blockedUser: The user to remove from the list of blocked users.
    public func remove(blockedUser: User) {
        callInfo.blockedUsers.removeAll { user in
            user.id == blockedUser.id
        }
    }
    
    internal func update(isReconnecting: Bool) {
        if isReconnecting != self.reconnecting {
            self.reconnecting = isReconnecting
        }
    }
    
    internal func update(callInfo: CallInfo) {
        self.callInfo = callInfo
    }
    
    internal func update(recordingState: RecordingState) {
        self.recordingState = recordingState
    }
    
}

public struct CallInfo: Sendable {
    public let cId: String
    public let backstage: Bool
    public var blockedUsers: [User]
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

public enum RecordingState {
    case noRecording
    case requested
    case recording
}
