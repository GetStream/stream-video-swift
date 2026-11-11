//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class EgressHLSResponse: @unchecked Sendable, Decodable {
    public var playlistUrl: String
    public var status: String

    public init(playlistUrl: String, status: String) {
        self.playlistUrl = playlistUrl
        self.status = status
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.playlistUrl = try container.decode(String.self, forKey: .playlistUrl)
        self.status = try container.decode(String.self, forKey: .status)
    }
}

extension EgressHLSResponse: Hashable {
    public static func == (lhs: EgressHLSResponse, rhs: EgressHLSResponse) -> Bool {
        lhs.playlistUrl == rhs.playlistUrl &&
            lhs.status == rhs.status
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(playlistUrl)
        hasher.combine(status)
    }
}
