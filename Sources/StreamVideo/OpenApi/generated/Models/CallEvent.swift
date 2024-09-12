//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public final class CallEvent: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var additional: [String: RawJSON]?
    public var component: String?
    public var description: String
    public var endTimestamp: Int
    public var severity: Int
    public var timestamp: Int
    public var type: String

    public init(
        additional: [String: RawJSON]? = nil,
        component: String? = nil,
        description: String,
        endTimestamp: Int,
        severity: Int,
        timestamp: Int,
        type: String
    ) {
        self.additional = additional
        self.component = component
        self.description = description
        self.endTimestamp = endTimestamp
        self.severity = severity
        self.timestamp = timestamp
        self.type = type
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case additional
        case component
        case description
        case endTimestamp = "end_timestamp"
        case severity
        case timestamp
        case type
    }
    
    public static func == (lhs: CallEvent, rhs: CallEvent) -> Bool {
        lhs.additional == rhs.additional &&
            lhs.component == rhs.component &&
            lhs.description == rhs.description &&
            lhs.endTimestamp == rhs.endTimestamp &&
            lhs.severity == rhs.severity &&
            lhs.timestamp == rhs.timestamp &&
            lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(additional)
        hasher.combine(component)
        hasher.combine(description)
        hasher.combine(endTimestamp)
        hasher.combine(severity)
        hasher.combine(timestamp)
        hasher.combine(type)
    }
}
