//
// Thresholds.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
/** Sets thresholds for AI moderation */

public struct Thresholds: Codable, JSONEncodable, Hashable {
    public var explicit: LabelThresholds?
    public var spam: LabelThresholds?
    public var toxic: LabelThresholds?

    public init(explicit: LabelThresholds? = nil, spam: LabelThresholds? = nil, toxic: LabelThresholds? = nil) {
        self.explicit = explicit
        self.spam = spam
        self.toxic = toxic
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case explicit
        case spam
        case toxic
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(explicit, forKey: .explicit)
        try container.encodeIfPresent(spam, forKey: .spam)
        try container.encodeIfPresent(toxic, forKey: .toxic)
    }
}

