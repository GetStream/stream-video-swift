//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent when call recording has stopped
public final class CallRecordingStoppedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, WSCallEvent {
    
    public enum CallRecordingStoppedEventRecordingType: String, Sendable, Codable, CaseIterable {
        case composite
        case individual
        case raw
        case unknown = "_unknown"

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let decodedValue = try? container.decode(String.self),
               let value = Self(rawValue: decodedValue) {
                self = value
            } else {
                self = .unknown
            }
        }
    }

    public var callCid: String
    public var createdAt: Date
    public var egressId: String
    /// The type of recording
    public var recordingType: CallRecordingStoppedEventRecordingType
    /// The type of event: "call.recording_stopped" in this case
    public var type: String = "call.recording_stopped"

    public init(callCid: String, createdAt: Date, egressId: String, recordingType: CallRecordingStoppedEventRecordingType) {
        self.callCid = callCid
        self.createdAt = createdAt
        self.egressId = egressId
        self.recordingType = recordingType
    }

    public enum CodingKeys: String, CodingKey {
        case callCid = "call_cid"
        case createdAt = "created_at"
        case egressId = "egress_id"
        case recordingType = "recording_type"
        case type
    }
}

extension CallRecordingStoppedEvent: Hashable {
    public static func == (lhs: CallRecordingStoppedEvent, rhs: CallRecordingStoppedEvent) -> Bool {
        lhs.callCid == rhs.callCid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.egressId == rhs.egressId &&
            lhs.recordingType == rhs.recordingType &&
            lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(callCid)
        hasher.combine(createdAt)
        hasher.combine(egressId)
        hasher.combine(recordingType)
        hasher.combine(type)
    }
}
