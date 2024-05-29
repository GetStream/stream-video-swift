//
// CallIngressResponse.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation


public struct CallIngressResponse: Codable, JSONEncodable, Hashable {
    public var rtmp: RTMPIngress

    public init(rtmp: RTMPIngress) {
        self.rtmp = rtmp
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case rtmp
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(rtmp, forKey: .rtmp)
    }
}

