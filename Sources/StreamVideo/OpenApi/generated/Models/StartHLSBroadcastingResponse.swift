//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct StartHLSBroadcastingResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var duration: String
    public var playlistUrl: String

    public init(duration: String, playlistUrl: String) {
        self.duration = duration
        self.playlistUrl = playlistUrl
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case playlistUrl = "playlist_url"
    }
}
