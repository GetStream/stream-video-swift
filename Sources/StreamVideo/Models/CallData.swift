//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

/// Represents the data for a call.
public struct CallData: @unchecked Sendable {
    /// The unique identifier for the call.
    public let callCid: String
    /// The members participating in the call.
    public var members: [Member]
    /// The users who are blocked from joining the call.
    public var blockedUsers: [User]
    /// The date and time when the call was created.
    public let createdAt: Date
    /// Indicates whether the call is in backstage mode.
    public var backstage: Bool
    /// Indicates whether the call is currently broadcasting.
    public var broadcasting: Bool
    /// The date and time when the call ended, if applicable.
    public var endedAt: Date?
    /// Indicates whether the call is being recorded.
    public var recording: Bool
    /// The date and time when the call starts, if scheduled.
    public var startsAt: Date?
    /// The date and time when the call was last updated.
    public var updatedAt: Date
    /// The URL of the HLS playlist for the call.
    public var hlsPlaylistUrl: String
    /// The timeout duration (in seconds) for auto rejection.
    public var autoRejectTimeout: Int
    /// Custom data associated with the call.
    public var customData: [String: RawJSON]
    /// The session associated with the call.
    public var session: CallSession?
    /// The user who created the call.
    public var createdBy: User
}

/// Represents a session associated with a call.
public struct CallSession: Sendable {
    /// The users who accepted the call and the date when they accepted.
    public var acceptedBy: [String: Date]
    /// The date and time when the session ended, if applicable.
    public var endedAt: Date?
    /// The unique identifier for the session.
    public var id: String
    /// The participants in the session.
    public var participants: [User]
    /// The count of participants categorized by role.
    public var participantsCountByRole: [String: Int]
    /// The users who rejected the call and the date when they rejected.
    public var rejectedBy: [String: Date]
    /// The date and time when the session started.
    public var startedAt: Date?
}


extension CallSessionResponse {
    
    func toCallSession() -> CallSession {
        CallSession(
            acceptedBy: acceptedBy,
            endedAt: endedAt,
            id: id,
            participants: participants.map { $0.user.toUser },
            participantsCountByRole: participantsCountByRole,
            rejectedBy: rejectedBy,
            startedAt: startedAt
        )
    }
    
}

extension CallData {
    mutating func applyUpdates(from callResponse: CallResponse) {
        self.backstage = callResponse.backstage
        self.broadcasting = callResponse.egress.broadcasting
        self.endedAt = callResponse.endedAt
        self.recording = callResponse.recording
        self.startsAt = callResponse.startsAt
        self.updatedAt = callResponse.updatedAt
        self.hlsPlaylistUrl = callResponse.egress.hls?.playlistUrl ?? ""
        self.session = callResponse.session?.toCallSession()
        self.autoRejectTimeout = callResponse.settings.ring.autoCancelTimeoutMs
        self.createdBy = callResponse.createdBy.toUser
    }
}
