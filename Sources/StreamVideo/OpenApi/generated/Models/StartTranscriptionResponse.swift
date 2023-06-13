//
// StartTranscriptionResponse.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif





public struct StartTranscriptionResponse: Codable, JSONEncodable, Hashable {

    public var duration: String

    public init(duration: String) {
        self.duration = duration
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(duration, forKey: .duration)
    }
}

