//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class EgressRTMPResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
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
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case name
        case startedAt = "started_at"
        case streamKey = "stream_key"
        case streamUrl = "stream_url"
    }
    
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
