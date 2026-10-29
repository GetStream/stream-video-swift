//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// RTMP input settings
public final class RTMPIngress: @unchecked Sendable, Codable, JSONEncodable {
    public var address: String

    public init(address: String) {
        self.address = address
    }

    public enum CodingKeys: String, CodingKey {
        case address
    }
}

extension RTMPIngress: Hashable {
    public static func == (lhs: RTMPIngress, rhs: RTMPIngress) -> Bool {
        lhs.address == rhs.address
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(address)
    }
}
