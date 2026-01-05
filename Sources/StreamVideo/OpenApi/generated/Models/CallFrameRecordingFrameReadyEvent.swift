//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class CallFrameRecordingFrameReadyEvent: @unchecked Sendable,  Event, Codable, JSONEncodable, Hashable, WSCallEvent {
    public var callCid: String
    public var capturedAt: Date
    public var createdAt: Date
    public var egressId: String
    public var sessionId: String
    public var trackType: String
    public var type: String = "call.frame_recording_ready"
    public var url: String
    public var users: [String: UserResponse]

    public init(callCid: String, capturedAt: Date, createdAt: Date, egressId: String, sessionId: String, trackType: String, url: String, users: [String: UserResponse]) {
        self.callCid = callCid
        self.capturedAt = capturedAt
        self.createdAt = createdAt
        self.egressId = egressId
        self.sessionId = sessionId
        self.trackType = trackType
        self.url = url
        self.users = users
    }

public enum CodingKeys: String, CodingKey, CaseIterable {
    case callCid = "call_cid"
    case capturedAt = "captured_at"
    case createdAt = "created_at"
    case egressId = "egress_id"
    case sessionId = "session_id"
    case trackType = "track_type"
    case type
    case url
    case users
}

    public static func == (lhs: CallFrameRecordingFrameReadyEvent, rhs: CallFrameRecordingFrameReadyEvent) -> Bool {
        lhs.callCid == rhs.callCid &&
        lhs.capturedAt == rhs.capturedAt &&
        lhs.createdAt == rhs.createdAt &&
        lhs.egressId == rhs.egressId &&
        lhs.sessionId == rhs.sessionId &&
        lhs.trackType == rhs.trackType &&
        lhs.type == rhs.type &&
        lhs.url == rhs.url &&
        lhs.users == rhs.users
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(callCid)
        hasher.combine(capturedAt)
        hasher.combine(createdAt)
        hasher.combine(egressId)
        hasher.combine(sessionId)
        hasher.combine(trackType)
        hasher.combine(type)
        hasher.combine(url)
        hasher.combine(users)
    }
}
