//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct EgressRTMPResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var name: String
    public var startedAt: Date
    public var streamKey: String? = nil
    public var streamUrl: String? = nil

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
}
