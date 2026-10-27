//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// BlockUserResponse is the payload for blocking a user.
public final class BlockUserResponse: @unchecked Sendable, Codable, JSONEncodable {
    /// Duration of the request in milliseconds
    public var duration: String

    public init(duration: String) {
        self.duration = duration
    }

    public enum CodingKeys: String, CodingKey {
        case duration
    }
}

extension BlockUserResponse: Hashable {
    public static func == (lhs: BlockUserResponse, rhs: BlockUserResponse) -> Bool {
        lhs.duration == rhs.duration
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
    }
}
