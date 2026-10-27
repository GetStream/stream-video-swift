//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class EgressHLSResponse: @unchecked Sendable, Decodable {
    public var playlistUrl: String

    public init(playlistUrl: String) {
        self.playlistUrl = playlistUrl
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.playlistUrl = try container.decode(String.self, forKey: .playlistUrl)
    }
}

extension EgressHLSResponse: Hashable {
    public static func == (lhs: EgressHLSResponse, rhs: EgressHLSResponse) -> Bool {
        lhs.playlistUrl == rhs.playlistUrl
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(playlistUrl)
    }
}
