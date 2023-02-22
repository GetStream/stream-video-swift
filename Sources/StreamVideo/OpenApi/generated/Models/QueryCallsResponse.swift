//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct QueryCallsResponse: Codable, JSONEncodable, Hashable {

    internal var calls: [CallStateResponseFields]
    internal var duration: String
    internal var next: String?
    internal var prev: String?

    internal init(calls: [CallStateResponseFields], duration: String, next: String? = nil, prev: String? = nil) {
        self.calls = calls
        self.duration = duration
        self.next = next
        self.prev = prev
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case calls
        case duration
        case next
        case prev
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(calls, forKey: .calls)
        try container.encode(duration, forKey: .duration)
        try container.encodeIfPresent(next, forKey: .next)
        try container.encodeIfPresent(prev, forKey: .prev)
    }
}
