//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent when call recording is ready
public final class CallRecordingReadyEvent: @unchecked Sendable, Event, Codable, JSONEncodable, WSCallEvent {
    
    public var callCid: String
    /// CallRecording represents a recording of a call.
    public var callRecording: CallRecording
    public var createdAt: Date
    /// The type of event: "call.recording_ready" in this case
    public var type: String = "call.recording_ready"

    public init(callCid: String, callRecording: CallRecording, createdAt: Date) {
        self.callCid = callCid
        self.callRecording = callRecording
        self.createdAt = createdAt
    }

    public enum CodingKeys: String, CodingKey {
        case callCid = "call_cid"
        case callRecording = "call_recording"
        case createdAt = "created_at"
        case type
    }
}

extension CallRecordingReadyEvent: Hashable {
    public static func == (lhs: CallRecordingReadyEvent, rhs: CallRecordingReadyEvent) -> Bool {
        lhs.callCid == rhs.callCid &&
            lhs.callRecording == rhs.callRecording &&
            lhs.createdAt == rhs.createdAt &&
            lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(callCid)
        hasher.combine(callRecording)
        hasher.combine(createdAt)
        hasher.combine(type)
    }
}
