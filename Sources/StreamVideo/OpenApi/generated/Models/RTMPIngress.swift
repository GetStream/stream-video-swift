//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// RTMP input settings
public final class RTMPIngress: @unchecked Sendable, Decodable {
    public var address: String

    public init(address: String) {
        self.address = address
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.address = try container.decode(String.self, forKey: .address)
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
