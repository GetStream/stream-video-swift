//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class CallTranscriptionReadyEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable, WSCallEvent {
    
    public var callCid: String
    public var callTranscription: CallTranscription
    public var createdAt: Date
    public var type: String = "call.transcription_ready"

    public init(callCid: String, callTranscription: CallTranscription, createdAt: Date) {
        self.callCid = callCid
        self.callTranscription = callTranscription
        self.createdAt = createdAt
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case callCid = "call_cid"
        case callTranscription = "call_transcription"
        case createdAt = "created_at"
        case type
    }
    
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
