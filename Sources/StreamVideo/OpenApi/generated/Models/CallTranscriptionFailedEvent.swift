//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent when call transcription has failed
public final class CallTranscriptionFailedEvent: Sendable, Event, Decodable, WSCallEvent {
    public let callCid: String
    public let createdAt: Date
    public let egressId: String
    /// The error message detailing why transcription failed.
    public let error: String?
    /// The type of event: "call.transcription_failed" in this case
    public let type: String

    public init(
        callCid: String,
        createdAt: Date,
        egressId: String,
        error: String? = nil,
        type: String = "call.transcription_failed"
    ) {
        self.callCid = callCid
        self.createdAt = createdAt
        self.egressId = egressId
        self.error = error
        self.type = type
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.callCid = try container.decode(String.self, forKey: .callCid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.egressId = try container.decode(String.self, forKey: .egressId)
        self.error = try container.decodeIfPresent(String.self, forKey: .error)
        self.type = try container.decode(String.self, forKey: .type)
    }
}

extension CallTranscriptionFailedEvent: Hashable {
    public static func == (lhs: CallTranscriptionFailedEvent, rhs: CallTranscriptionFailedEvent) -> Bool {
        lhs.callCid == rhs.callCid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.egressId == rhs.egressId &&
            lhs.error == rhs.error &&
            lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(callCid)
        hasher.combine(createdAt)
        hasher.combine(egressId)
        hasher.combine(error)
        hasher.combine(type)
    }
}
