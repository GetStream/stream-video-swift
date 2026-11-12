//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent when call transcription has stopped
public final class CallTranscriptionStoppedEvent: Sendable, Event, Decodable, WSCallEvent {
    public let callCid: String
    public let createdAt: Date
    public let egressId: String
    /// The type of event: "call.transcription_stopped" in this case
    public let type: String

    public init(callCid: String, createdAt: Date, egressId: String, type: String = "call.transcription_stopped") {
        self.callCid = callCid
        self.createdAt = createdAt
        self.egressId = egressId
        self.type = type
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.callCid = try container.decode(String.self, forKey: .callCid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.egressId = try container.decode(String.self, forKey: .egressId)
        self.type = try container.decode(String.self, forKey: .type)
    }
}

extension CallTranscriptionStoppedEvent: Hashable {
    public static func == (lhs: CallTranscriptionStoppedEvent, rhs: CallTranscriptionStoppedEvent) -> Bool {
        lhs.callCid == rhs.callCid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.egressId == rhs.egressId &&
            lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(callCid)
        hasher.combine(createdAt)
        hasher.combine(egressId)
        hasher.combine(type)
    }
}
