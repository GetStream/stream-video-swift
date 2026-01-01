//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class EgressHLSResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var playlistUrl: String

    public init(playlistUrl: String) {
        self.playlistUrl = playlistUrl
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case playlistUrl = "playlist_url"
    }
    
    public static func == (lhs: EgressHLSResponse, rhs: EgressHLSResponse) -> Bool {
        lhs.playlistUrl == rhs.playlistUrl
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(playlistUrl)
    }
}
