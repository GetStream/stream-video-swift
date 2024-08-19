//
// BroadcastSettingsRequest.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation


public struct BroadcastSettingsRequest: Codable, JSONEncodable, Hashable {
    public var enabled: Bool?
    public var hls: HLSSettingsRequest?
    public var rtmp: RTMPSettingsRequest?

    public init(enabled: Bool? = nil, hls: HLSSettingsRequest? = nil, rtmp: RTMPSettingsRequest? = nil) {
        self.enabled = enabled
        self.hls = hls
        self.rtmp = rtmp
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case enabled
        case hls
        case rtmp
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(enabled, forKey: .enabled)
        try container.encodeIfPresent(hls, forKey: .hls)
        try container.encodeIfPresent(rtmp, forKey: .rtmp)
    }
}

