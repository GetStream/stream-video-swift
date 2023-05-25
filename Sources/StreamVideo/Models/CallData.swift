//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

public struct CallData: @unchecked Sendable {
    public let callCid: String
    public var members: [User]
    public var blockedUsers: [User]
    public let createdAt: Date
    public var backstage: Bool
    public var broadcasting: Bool
    public var endedAt: Date?
    public var recording: Bool
    public var startsAt: Date?
    public var updatedAt: Date
    public var hlsPlaylistUrl: String
    public var autoRejectTimeout: Int
    public var customData: [String: Any]
    public var session: CallSession?
    public var createdBy: User
}

public struct CallSession: Sendable {
    public var acceptedBy: [String: Date]
    public var endedAt: Date?
    public var id: String
    public var participants: [User]
    public var participantsCountByRole: [String: Int]
    public var rejectedBy: [String: Date]
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
        self.broadcasting = callResponse.broadcasting
        self.endedAt = callResponse.endedAt
        self.recording = callResponse.recording
        self.startsAt = callResponse.startsAt
        self.updatedAt = callResponse.updatedAt
        self.hlsPlaylistUrl = callResponse.hlsPlaylistUrl
        self.session = callResponse.session?.toCallSession()
        self.autoRejectTimeout = callResponse.settings.ring.autoCancelTimeoutMs
        self.createdBy = callResponse.createdBy.toUser
    }
}
