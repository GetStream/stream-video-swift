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
    @Published public private(set) var callInfo: CallInfo
    @Published public private(set) var reconnecting = false
    @Published public private(set) var recordingState: RecordingState
    
    public let callId: String
    public let callType: CallType
    public let sessionId: String
    
    public var cId: String {
        "\(callType.name):\(callId)"
    }
    
    var onParticipantEvent: ((ParticipantEvent) -> Void)?
    
    private let syncQueue = DispatchQueue(label: "io.getstream.CallQueue", qos: .userInitiated)
    
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
    
    public func add(blockedUser: User) {
        var blockedUsers = callInfo.blockedUsers
        if !blockedUsers.contains(blockedUser) {
            blockedUsers.append(blockedUser)
            callInfo.blockedUsers = blockedUsers
        }
    }
    
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
