//
// CallBroadcastingStartedEvent.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
/** This event is sent when call broadcasting has started */

public struct CallBroadcastingStartedEvent: Codable, JSONEncodable, Hashable, WSCallEvent {
    public var callCid: String
    public var createdAt: Date
    public var hlsPlaylistUrl: String
    /** The type of event: \"call.broadcasting_started\" in this case */
    public var type: String = "call.broadcasting_started"

    public init(callCid: String, createdAt: Date, hlsPlaylistUrl: String, type: String = "call.broadcasting_started") {
        self.callCid = callCid
        self.createdAt = createdAt
        self.hlsPlaylistUrl = hlsPlaylistUrl
        self.type = type
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case callCid = "call_cid"
        case createdAt = "created_at"
        case hlsPlaylistUrl = "hls_playlist_url"
        case type
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(callCid, forKey: .callCid)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(hlsPlaylistUrl, forKey: .hlsPlaylistUrl)
        try container.encode(type, forKey: .type)
    }
}

