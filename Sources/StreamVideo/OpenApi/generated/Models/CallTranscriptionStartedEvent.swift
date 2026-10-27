//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent when call transcription has started
public final class CallTranscriptionStartedEvent: @unchecked Sendable, Event, Decodable, WSCallEvent {
    public var callCid: String
    public var createdAt: Date
    /// The type of event: "call.transcription_started" in this case
    public var type: String = "call.transcription_started"

    public init(callCid: String, createdAt: Date) {
        self.callCid = callCid
        self.createdAt = createdAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.callCid = try container.decode(String.self, forKey: .callCid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.type = try container.decode(String.self, forKey: .type)
    }
}

extension CallTranscriptionStartedEvent: Hashable {
    public static func == (lhs: CallTranscriptionStartedEvent, rhs: CallTranscriptionStartedEvent) -> Bool {
        lhs.callCid == rhs.callCid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(callCid)
        hasher.combine(createdAt)
        hasher.combine(type)
    }
}
