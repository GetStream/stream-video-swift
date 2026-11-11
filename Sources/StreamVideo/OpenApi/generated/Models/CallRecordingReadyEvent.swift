//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent when call recording is ready
public final class CallRecordingReadyEvent: Sendable, Event, Decodable, WSCallEvent {
    
    public enum CallRecordingReadyEventRecordingType: String, Sendable, Codable, CaseIterable {
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

    public let callCid: String
    /// CallRecording represents a recording of a call.
    public let callRecording: CallRecording
    public let createdAt: Date
    public let egressId: String
    /// The type of recording
    public let recordingType: CallRecordingReadyEventRecordingType
    /// The type of event: "call.recording_ready" in this case
    public let type: String

    public init(
        callCid: String,
        callRecording: CallRecording,
        createdAt: Date,
        egressId: String,
        recordingType: CallRecordingReadyEventRecordingType,
        type: String = "call.recording_ready"
    ) {
        self.callCid = callCid
        self.callRecording = callRecording
        self.createdAt = createdAt
        self.egressId = egressId
        self.recordingType = recordingType
        self.type = type
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.callCid = try container.decode(String.self, forKey: .callCid)
        self.callRecording = try container.decode(CallRecording.self, forKey: .callRecording)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.egressId = try container.decode(String.self, forKey: .egressId)
        self.recordingType = try container.decode(CallRecordingReadyEventRecordingType.self, forKey: .recordingType)
        self.type = try container.decode(String.self, forKey: .type)
    }
}

extension CallRecordingReadyEvent: Hashable {
    public static func == (lhs: CallRecordingReadyEvent, rhs: CallRecordingReadyEvent) -> Bool {
        lhs.callCid == rhs.callCid &&
            lhs.callRecording == rhs.callRecording &&
            lhs.createdAt == rhs.createdAt &&
            lhs.egressId == rhs.egressId &&
            lhs.recordingType == rhs.recordingType &&
            lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(callCid)
        hasher.combine(callRecording)
        hasher.combine(createdAt)
        hasher.combine(egressId)
        hasher.combine(recordingType)
        hasher.combine(type)
    }
}
