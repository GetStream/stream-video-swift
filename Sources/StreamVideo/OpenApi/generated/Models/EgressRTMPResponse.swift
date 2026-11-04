//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class EgressRTMPResponse: @unchecked Sendable, Decodable {
    public var name: String
    public var startedAt: Date
    public var streamKey: String?
    public var streamUrl: String?

    public init(name: String, startedAt: Date, streamKey: String? = nil, streamUrl: String? = nil) {
        self.name = name
        self.startedAt = startedAt
        self.streamKey = streamKey
        self.streamUrl = streamUrl
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.startedAt = try container.decode(Date.self, forKey: .startedAt)
        self.streamKey = try container.decodeIfPresent(String.self, forKey: .streamKey)
        self.streamUrl = try container.decodeIfPresent(String.self, forKey: .streamUrl)
    }
}

extension EgressRTMPResponse: Hashable {
    public static func == (lhs: EgressRTMPResponse, rhs: EgressRTMPResponse) -> Bool {
        lhs.name == rhs.name &&
            lhs.startedAt == rhs.startedAt &&
            lhs.streamKey == rhs.streamKey &&
            lhs.streamUrl == rhs.streamUrl
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(startedAt)
        hasher.combine(streamKey)
        hasher.combine(streamUrl)
    }
}
