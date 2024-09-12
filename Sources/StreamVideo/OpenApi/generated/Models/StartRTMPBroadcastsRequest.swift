//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public final class StartRTMPBroadcastsRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var layout: LayoutSettings?
    public var name: String
    public var quality: String?
    public var streamKey: String?
    public var streamUrl: String

    public init(layout: LayoutSettings? = nil, name: String, quality: String? = nil, streamKey: String? = nil, streamUrl: String) {
        self.layout = layout
        self.name = name
        self.quality = quality
        self.streamKey = streamKey
        self.streamUrl = streamUrl
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case layout
        case name
        case quality
        case streamKey = "stream_key"
        case streamUrl = "stream_url"
    }
    
    public static func == (lhs: StartRTMPBroadcastsRequest, rhs: StartRTMPBroadcastsRequest) -> Bool {
        lhs.layout == rhs.layout &&
            lhs.name == rhs.name &&
            lhs.quality == rhs.quality &&
            lhs.streamKey == rhs.streamKey &&
            lhs.streamUrl == rhs.streamUrl
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(layout)
        hasher.combine(name)
        hasher.combine(quality)
        hasher.combine(streamKey)
        hasher.combine(streamUrl)
    }
}
