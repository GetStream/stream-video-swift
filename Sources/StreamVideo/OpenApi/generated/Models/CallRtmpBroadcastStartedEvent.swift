//
// CallRtmpBroadcastStartedEvent.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
/** This event is sent when RTMP broadcast has started */

public struct CallRtmpBroadcastStartedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable, WSCallEvent {
    public var callCid: String
    public var createdAt: Date
    public var name: String
    /** The type of event: \"call.rtmp_broadcast_started\" in this case */
    public var type: String = "call.rtmp_broadcast_started"

    public init(callCid: String, createdAt: Date, name: String, type: String = "call.rtmp_broadcast_started") {
        self.callCid = callCid
        self.createdAt = createdAt
        self.name = name
        self.type = type
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case callCid = "call_cid"
        case createdAt = "created_at"
        case name
        case type
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(callCid, forKey: .callCid)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
    }
}

