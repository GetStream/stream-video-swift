//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// StartRTMPBroadcastsRequest is the payload for starting RTMP broadcasts.
public final class StartRTMPBroadcastsRequest: @unchecked Sendable, Codable, JSONEncodable {
    /// List of broadcasts to start
    public var broadcasts: [RTMPBroadcastRequest]

    public init(broadcasts: [RTMPBroadcastRequest]) {
        self.broadcasts = broadcasts
    }

    public enum CodingKeys: String, CodingKey {
        case broadcasts
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
