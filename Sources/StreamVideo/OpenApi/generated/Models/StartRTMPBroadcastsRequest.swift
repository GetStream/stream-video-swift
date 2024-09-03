//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct StartRTMPBroadcastsRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var layout: LayoutSettings? = nil
    public var name: String
    public var quality: String? = nil
    public var streamKey: String? = nil
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
}
