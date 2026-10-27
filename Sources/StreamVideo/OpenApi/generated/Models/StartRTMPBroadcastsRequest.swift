//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// StartRTMPBroadcastsRequest is the payload for starting RTMP broadcasts.
public final class StartRTMPBroadcastsRequest: @unchecked Sendable, Encodable, JSONEncodable {
    /// List of broadcasts to start
    public var broadcasts: [RTMPBroadcastRequest]

    public init(broadcasts: [RTMPBroadcastRequest]) {
        self.broadcasts = broadcasts
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(broadcasts, forKey: .broadcasts)
    }
}

extension StartRTMPBroadcastsRequest: Hashable {
    public static func == (lhs: StartRTMPBroadcastsRequest, rhs: StartRTMPBroadcastsRequest) -> Bool {
        lhs.broadcasts == rhs.broadcasts
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(broadcasts)
    }
}
