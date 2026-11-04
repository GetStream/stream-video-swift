//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// MuteUsersResponse is the response payload for the mute users endpoint.
public final class MuteUsersResponse: @unchecked Sendable, Codable, JSONEncodable {
    /// Duration of the request in milliseconds
    public var duration: String

    public init(duration: String) {
        self.duration = duration
    }

    public enum CodingKeys: String, CodingKey {
        case duration
    }
}

extension MuteUsersResponse: Hashable {
    public static func == (lhs: MuteUsersResponse, rhs: MuteUsersResponse) -> Bool {
        lhs.duration == rhs.duration
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
    }
}
