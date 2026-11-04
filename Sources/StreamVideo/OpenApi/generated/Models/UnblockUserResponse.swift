//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// UnblockUserResponse is the payload for unblocking a user.
public final class UnblockUserResponse: @unchecked Sendable, Codable, JSONEncodable {
    /// Duration of the request in milliseconds
    public var duration: String

    public init(duration: String) {
        self.duration = duration
    }

    public enum CodingKeys: String, CodingKey {
        case duration
    }
}

extension UnblockUserResponse: Hashable {
    public static func == (lhs: UnblockUserResponse, rhs: UnblockUserResponse) -> Bool {
        lhs.duration == rhs.duration
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
    }
}
