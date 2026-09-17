//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class StartRTMPBroadcastsRequest: @unchecked Sendable, Encodable, JSONEncodable, Hashable {
    
    public var broadcasts: [RTMPBroadcastRequest]

    public init(broadcasts: [RTMPBroadcastRequest]) {
        self.broadcasts = broadcasts
    }
    
    public enum CodingKeys: String, CodingKey {
        case broadcasts
    }
    
    public static func == (lhs: StartRTMPBroadcastsRequest, rhs: StartRTMPBroadcastsRequest) -> Bool {
        lhs.broadcasts == rhs.broadcasts
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(broadcasts)
    }
}
