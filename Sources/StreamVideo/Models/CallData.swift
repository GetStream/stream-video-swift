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
    public var session: CallSessionResponse?
    /// The user who created the call.
    public var createdBy: User
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
        self.session = callResponse.session
        self.autoRejectTimeout = callResponse.settings.ring.autoCancelTimeoutMs
        self.createdBy = callResponse.createdBy.toUser
    }
}
