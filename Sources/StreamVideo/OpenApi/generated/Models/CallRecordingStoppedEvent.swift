//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class CallRecordingStoppedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable, WSCallEvent {
    
    public enum CallRecordingStoppedEventRecordingType: String, Sendable, Codable, CaseIterable {
        case composite = "composite"
        case individual = "individual"
        case raw = "raw"
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
    public var recordingType: CallRecordingStoppedEventRecordingType
    public var type: String = "call.recording_stopped"

    public init(callCid: String, createdAt: Date, egressId: String, recordingType: CallRecordingStoppedEventRecordingType) {
        self.callCid = callCid
        self.createdAt = createdAt
        self.egressId = egressId
        self.recordingType = recordingType
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case callCid = "call_cid"
        case createdAt = "created_at"
        case egressId = "egress_id"
        case recordingType = "recording_type"
        case type
    }

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
