//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct SendEventRequest: Codable, JSONEncodable, Hashable {

    internal var custom: [String: AnyCodable]?
    internal var eventType: String

    internal init(custom: [String: AnyCodable]? = nil, eventType: String) {
        self.custom = custom
        self.eventType = eventType
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case custom
        case eventType = "event_type"
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(custom, forKey: .custom)
        try container.encode(eventType, forKey: .eventType)
    }
}
