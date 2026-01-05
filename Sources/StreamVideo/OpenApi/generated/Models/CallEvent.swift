//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class CallEvent: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var _internal: Bool
    public var category: String?
    public var component: String?
    public var description: String
    public var endTimestamp: Int
    public var issueTags: [String]?
    public var kind: String
    public var severity: Int
    public var timestamp: Int
    public var type: String

    public init(
        _internal: Bool,
        category: String? = nil,
        component: String? = nil,
        description: String,
        endTimestamp: Int,
        issueTags: [String]? = nil,
        kind: String,
        severity: Int,
        timestamp: Int,
        type: String
    ) {
        self._internal = _internal
        self.category = category
        self.component = component
        self.description = description
        self.endTimestamp = endTimestamp
        self.issueTags = issueTags
        self.kind = kind
        self.severity = severity
        self.timestamp = timestamp
        self.type = type
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case _internal = "internal"
        case category
        case component
        case description
        case endTimestamp = "end_timestamp"
        case issueTags = "issue_tags"
        case kind
        case severity
        case timestamp
        case type
    }
    
    public static func == (lhs: CallEvent, rhs: CallEvent) -> Bool {
        lhs._internal == rhs._internal &&
            lhs.category == rhs.category &&
            lhs.component == rhs.component &&
            lhs.description == rhs.description &&
            lhs.endTimestamp == rhs.endTimestamp &&
            lhs.issueTags == rhs.issueTags &&
            lhs.kind == rhs.kind &&
            lhs.severity == rhs.severity &&
            lhs.timestamp == rhs.timestamp &&
            lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(_internal)
        hasher.combine(category)
        hasher.combine(component)
        hasher.combine(description)
        hasher.combine(endTimestamp)
        hasher.combine(issueTags)
        hasher.combine(kind)
        hasher.combine(severity)
        hasher.combine(timestamp)
        hasher.combine(type)
    }
}
