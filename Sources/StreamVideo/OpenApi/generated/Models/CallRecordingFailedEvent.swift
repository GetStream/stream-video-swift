//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent when call recording has failed
public final class CallRecordingFailedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, WSCallEvent {
    
    public var callCid: String
    public var createdAt: Date
    /// The type of event: "call.recording_failed" in this case
    public var type: String = "call.recording_failed"

    public init(callCid: String, createdAt: Date) {
        self.callCid = callCid
        self.createdAt = createdAt
    }

    public enum CodingKeys: String, CodingKey {
        case callCid = "call_cid"
        case createdAt = "created_at"
        case type
    }
}

extension CallRecordingFailedEvent: Hashable {
    public static func == (lhs: CallRecordingFailedEvent, rhs: CallRecordingFailedEvent) -> Bool {
        lhs.callCid == rhs.callCid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(callCid)
        hasher.combine(createdAt)
        hasher.combine(type)
    }
}
