//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// Basic response information
public final class GoLiveResponse: @unchecked Sendable, Codable, JSONEncodable {
    /// Represents a call
    public var call: CallResponse
    /// Duration of the request in milliseconds
    public var duration: String

    public init(call: CallResponse, duration: String) {
        self.call = call
        self.duration = duration
    }

    public enum CodingKeys: String, CodingKey {
        case call
        case duration
    }
}

extension GoLiveResponse: Hashable {
    public static func == (lhs: GoLiveResponse, rhs: GoLiveResponse) -> Bool {
        lhs.call == rhs.call &&
            lhs.duration == rhs.duration
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(call)
        hasher.combine(duration)
    }
}
