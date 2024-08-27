//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct EgressRTMPResponse: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var name: String
    public var streamKey: String
    public var url: String

    public init(name: String, streamKey: String, url: String) {
        self.name = name
        self.streamKey = streamKey
        self.url = url
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case name
        case streamKey = "stream_key"
        case url
    }
}
