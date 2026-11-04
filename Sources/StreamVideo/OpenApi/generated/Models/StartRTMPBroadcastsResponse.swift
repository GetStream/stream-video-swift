//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// StartRTMPBroadcastsResponse is the payload for starting an RTMP broadcast.
public final class StartRTMPBroadcastsResponse: Sendable, Decodable {
    /// Duration of the request in milliseconds
    public let duration: String

    public init(duration: String) {
        self.duration = duration
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.duration = try container.decode(String.self, forKey: .duration)
    }
}

extension StartRTMPBroadcastsResponse: Hashable {
    public static func == (lhs: StartRTMPBroadcastsResponse, rhs: StartRTMPBroadcastsResponse) -> Bool {
        lhs.duration == rhs.duration
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
    }
}
