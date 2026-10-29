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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.callCid = try container.decode(String.self, forKey: .callCid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.egressId = try container.decode(String.self, forKey: .egressId)
        self.recordingType = try container.decode(CallRecordingStoppedEventRecordingType.self, forKey: .recordingType)
        self.type = try container.decode(String.self, forKey: .type)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(callCid, forKey: .callCid)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(egressId, forKey: .egressId)
        try container.encode(recordingType, forKey: .recordingType)
        try container.encode(type, forKey: .type)
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
