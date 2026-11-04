//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent when call recording is ready
public final class CallRecordingReadyEvent: Sendable, Event, Decodable, WSCallEvent {
    public let callCid: String
    /// CallRecording represents a recording of a call.
    public let callRecording: CallRecording
    public let createdAt: Date
    /// The type of event: "call.recording_ready" in this case
    public let type: String

    public init(callCid: String, callRecording: CallRecording, createdAt: Date, type: String = "call.recording_ready") {
        self.callCid = callCid
        self.callRecording = callRecording
        self.createdAt = createdAt
        self.type = type
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.callCid = try container.decode(String.self, forKey: .callCid)
        self.callRecording = try container.decode(CallRecording.self, forKey: .callRecording)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.type = try container.decode(String.self, forKey: .type)
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
