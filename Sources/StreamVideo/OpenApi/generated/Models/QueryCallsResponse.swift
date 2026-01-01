//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class QueryCallsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var calls: [CallStateResponseFields]
    public var duration: String
    public var next: String?
    public var prev: String?

    public init(calls: [CallStateResponseFields], duration: String, next: String? = nil, prev: String? = nil) {
        self.calls = calls
        self.duration = duration
        self.next = next
        self.prev = prev
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case calls
        case duration
        case next
        case prev
    }
    
    public static func == (lhs: QueryCallsResponse, rhs: QueryCallsResponse) -> Bool {
        lhs.calls == rhs.calls &&
            lhs.duration == rhs.duration &&
            lhs.next == rhs.next &&
            lhs.prev == rhs.prev
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(calls)
        hasher.combine(duration)
        hasher.combine(next)
        hasher.combine(prev)
    }
}
