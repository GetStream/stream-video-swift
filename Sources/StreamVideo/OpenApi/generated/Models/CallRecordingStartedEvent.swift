//
// CallRecordingStartedEvent.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

/** This event is sent when call recording has started */




public struct CallRecordingStartedEvent: Codable, JSONEncodable, Hashable, WSCallEvent {

    public var callCid: String
    public var createdAt: Date
    /** The type of event: \"call.recording_started\" in this case */
    public var type: String = "call.recording_started"

    public init(callCid: String, createdAt: Date, type: String = "call.recording_started") {
        self.callCid = callCid
        self.createdAt = createdAt
        self.type = type
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case callCid = "call_cid"
        case createdAt = "created_at"
        case type
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(callCid, forKey: .callCid)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(type, forKey: .type)
    }
}

