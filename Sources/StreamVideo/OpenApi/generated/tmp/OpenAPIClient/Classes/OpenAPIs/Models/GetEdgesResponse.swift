//
// GetEdgesResponse.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation


public struct GetEdgesResponse: Codable, JSONEncodable, Hashable {
    /** Duration of the request in human-readable format */
    public var duration: String
    public var edges: [EdgeResponse]

    public init(duration: String, edges: [EdgeResponse]) {
        self.duration = duration
        self.edges = edges
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case edges
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(duration, forKey: .duration)
        try container.encode(edges, forKey: .edges)
    }
}

