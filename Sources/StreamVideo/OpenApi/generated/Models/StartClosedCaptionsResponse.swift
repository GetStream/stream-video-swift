//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class StartClosedCaptionsResponse: @unchecked Sendable, Codable, JSONEncodable {
    public var duration: String

    public init(duration: String) {
        self.duration = duration
    }

    public enum CodingKeys: String, CodingKey {
        case duration
    }
}

extension StartClosedCaptionsResponse: Hashable {
    public static func == (lhs: StartClosedCaptionsResponse, rhs: StartClosedCaptionsResponse) -> Bool {
        lhs.duration == rhs.duration
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
    }
}
