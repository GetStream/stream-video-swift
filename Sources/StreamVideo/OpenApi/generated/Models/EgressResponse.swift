//
// EgressResponse.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation


public struct EgressResponse: Codable, JSONEncodable, Hashable {
    public var broadcasting: Bool
    public var hls: EgressHLSResponse?
    public var rtmps: [EgressRTMPResponse]

    public init(broadcasting: Bool, hls: EgressHLSResponse? = nil, rtmps: [EgressRTMPResponse]) {
        self.broadcasting = broadcasting
        self.hls = hls
        self.rtmps = rtmps
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case broadcasting
        case hls
        case rtmps
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(broadcasting, forKey: .broadcasting)
        try container.encodeIfPresent(hls, forKey: .hls)
        try container.encode(rtmps, forKey: .rtmps)
    }
}

