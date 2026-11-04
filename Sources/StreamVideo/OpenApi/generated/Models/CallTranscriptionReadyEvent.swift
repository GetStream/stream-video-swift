//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent when call transcription is ready
public final class CallTranscriptionReadyEvent: @unchecked Sendable, Event, Decodable, WSCallEvent {
    public var callCid: String
    /// CallTranscription represents a transcription of a call.
    public var callTranscription: CallTranscription
    public var createdAt: Date
    /// The type of event: "call.transcription_ready" in this case
    public var type: String = "call.transcription_ready"

    public init(callCid: String, callTranscription: CallTranscription, createdAt: Date) {
        self.callCid = callCid
        self.callTranscription = callTranscription
        self.createdAt = createdAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.callCid = try container.decode(String.self, forKey: .callCid)
        self.callTranscription = try container.decode(CallTranscription.self, forKey: .callTranscription)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.type = try container.decode(String.self, forKey: .type)
    }
}

extension CallTranscriptionReadyEvent: Hashable {
    public static func == (lhs: CallTranscriptionReadyEvent, rhs: CallTranscriptionReadyEvent) -> Bool {
        lhs.callCid == rhs.callCid &&
            lhs.callTranscription == rhs.callTranscription &&
            lhs.createdAt == rhs.createdAt &&
            lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(callCid)
        hasher.combine(callTranscription)
        hasher.combine(createdAt)
        hasher.combine(type)
    }
}
