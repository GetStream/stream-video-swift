//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct EgressHLSResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var playlistUrl: String

    public init(playlistUrl: String) {
        self.playlistUrl = playlistUrl
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case playlistUrl = "playlist_url"
    }
}
