//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent when a frame is captured from a call
public final class CallFrameRecordingFrameReadyEvent: @unchecked Sendable, Event, Decodable, WSCallEvent {
    public var callCid: String
    /// The time the frame was captured
    public var capturedAt: Date
    public var createdAt: Date
    public var egressId: String
    /// Call session ID
    public var sessionId: String
    /// The type of the track frame was captured from (TRACK_TYPE_VIDEO|TRACK_TYPE_SCREEN_SHARE)
    public var trackType: String
    /// The type of event: "call.frame_recording_ready" in this case
    public var type: String = "call.frame_recording_ready"
    /// The URL of the frame
    public var url: String
    /// The users in the frame
    public var users: [String: UserResponse]

    public init(
        callCid: String,
        capturedAt: Date,
        createdAt: Date,
        egressId: String,
        sessionId: String,
        trackType: String,
        url: String,
        users: [String: UserResponse]
    ) {
        self.callCid = callCid
        self.capturedAt = capturedAt
        self.createdAt = createdAt
        self.egressId = egressId
        self.sessionId = sessionId
        self.trackType = trackType
        self.url = url
        self.users = users
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.callCid = try container.decode(String.self, forKey: .callCid)
        self.capturedAt = try container.decode(Date.self, forKey: .capturedAt)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.egressId = try container.decode(String.self, forKey: .egressId)
        self.sessionId = try container.decode(String.self, forKey: .sessionId)
        self.trackType = try container.decode(String.self, forKey: .trackType)
        self.type = try container.decode(String.self, forKey: .type)
        self.url = try container.decode(String.self, forKey: .url)
        self.users = try container.decode([String: UserResponse].self, forKey: .users)
    }
}

extension CallFrameRecordingFrameReadyEvent: Hashable {
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
