//
// SortParamRequest.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation


public struct SortParamRequest: Codable, JSONEncodable, Hashable {
    /** Direction of sorting, 1 for Ascending, -1 for Descending, default is 1 */
    public var direction: Int?
    /** Name of field to sort by */
    public var field: String?

    public init(direction: Int? = nil, field: String? = nil) {
        self.direction = direction
        self.field = field
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case direction
        case field
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(direction, forKey: .direction)
        try container.encodeIfPresent(field, forKey: .field)
    }
}

