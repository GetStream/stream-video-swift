//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class CallRecordingStoppedEventRecordingType: RawRepresentable, Codable, CustomStringConvertible, Hashable, Sendable {
    public let rawValue: String

    public var description: String { rawValue }

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let composite = CallRecordingStoppedEventRecordingType(rawValue: "composite")
    public static let individual = CallRecordingStoppedEventRecordingType(rawValue: "individual")
    public static let raw = CallRecordingStoppedEventRecordingType(rawValue: "raw")
}

/// This event is sent when call recording has stopped
public final class CallRecordingStoppedEvent: Sendable, Event, Decodable, WSCallEvent {
    public let callCid: String
    public let createdAt: Date
    public let egressId: String
    /// The type of recording
    public let recordingType: CallRecordingStoppedEventRecordingType
    /// The type of event: "call.recording_stopped" in this case
    public let type: String

    public init(
        callCid: String,
        createdAt: Date,
        egressId: String,
        recordingType: CallRecordingStoppedEventRecordingType,
        type: String = "call.recording_stopped"
    ) {
        self.callCid = callCid
        self.createdAt = createdAt
        self.egressId = egressId
        self.recordingType = recordingType
        self.type = type
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.callCid = try container.decode(String.self, forKey: .callCid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.egressId = try container.decode(String.self, forKey: .egressId)
        self.recordingType = try container.decode(CallRecordingStoppedEventRecordingType.self, forKey: .recordingType)
        self.type = try container.decode(String.self, forKey: .type)
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
