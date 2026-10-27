//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent when frame recording has stopped
public final class CallFrameRecordingStoppedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, WSCallEvent {
    /// Represents a call
    public var call: CallResponse
    public var callCid: String
    public var createdAt: Date
    public var egressId: String
    /// The type of event: "call.frame_recording_stopped" in this case
    public var type: String = "call.frame_recording_stopped"

    public init(call: CallResponse, callCid: String, createdAt: Date, egressId: String) {
        self.call = call
        self.callCid = callCid
        self.createdAt = createdAt
        self.egressId = egressId
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.call = try container.decode(CallResponse.self, forKey: .call)
        self.callCid = try container.decode(String.self, forKey: .callCid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.egressId = try container.decode(String.self, forKey: .egressId)
        self.type = try container.decode(String.self, forKey: .type)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(call, forKey: .call)
        try container.encode(callCid, forKey: .callCid)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(egressId, forKey: .egressId)
        try container.encode(type, forKey: .type)
    }
}

extension CallFrameRecordingStoppedEvent: Hashable {
    public static func == (lhs: CallFrameRecordingStoppedEvent, rhs: CallFrameRecordingStoppedEvent) -> Bool {
        lhs.call == rhs.call &&
            lhs.callCid == rhs.callCid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.egressId == rhs.egressId &&
            lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(call)
        hasher.combine(callCid)
        hasher.combine(createdAt)
        hasher.combine(egressId)
        hasher.combine(type)
    }
}
