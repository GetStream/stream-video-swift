//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct CallTranscriptionReadyEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable, WSCallEvent {
    
    public var callCid: String
    public var callTranscription: CallTranscription
    public var createdAt: Date
    public var type: String

    public init(callCid: String, callTranscription: CallTranscription, createdAt: Date, type: String) {
        self.callCid = callCid
        self.callTranscription = callTranscription
        self.createdAt = createdAt
        self.type = type
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case callCid = "call_cid"
        case callTranscription = "call_transcription"
        case createdAt = "created_at"
        case type
    }
}
