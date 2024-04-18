//
// CallTranscriptionReadyEvent.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
/** This event is sent when call transcription is ready */

public struct CallTranscriptionReadyEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable, WSCallEvent {
    public var callCid: String
    public var callTranscription: CallTranscription
    public var createdAt: Date
    /** The type of event: \"call.transcription_ready\" in this case */
    public var type: String = "call.transcription_ready"

    public init(callCid: String, callTranscription: CallTranscription, createdAt: Date, type: String = "call.transcription_ready") {
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

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(callCid, forKey: .callCid)
        try container.encode(callTranscription, forKey: .callTranscription)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(type, forKey: .type)
    }
}

