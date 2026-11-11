//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class SRTIngress: Sendable, Decodable {
    public let address: String

    public init(address: String) {
        self.address = address
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.address = try container.decode(String.self, forKey: .address)
    }
}

extension SRTIngress: Hashable {
    public static func == (lhs: SRTIngress, rhs: SRTIngress) -> Bool {
        lhs.address == rhs.address
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(address)
    }
}
