//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class CallFrameRecordingFailedEvent: @unchecked Sendable,  Event, Codable, JSONEncodable, Hashable, WSCallEvent {
    public var call: CallResponse
    public var callCid: String
    public var createdAt: Date
    public var egressId: String
    public var type: String = "call.frame_recording_failed"

    public init(call: CallResponse, callCid: String, createdAt: Date, egressId: String) {
        self.call = call
        self.callCid = callCid
        self.createdAt = createdAt
        self.egressId = egressId
    }

public enum CodingKeys: String, CodingKey, CaseIterable {
    case call
    case callCid = "call_cid"
    case createdAt = "created_at"
    case egressId = "egress_id"
    case type
}

    public static func == (lhs: CallFrameRecordingFailedEvent, rhs: CallFrameRecordingFailedEvent) -> Bool {
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
