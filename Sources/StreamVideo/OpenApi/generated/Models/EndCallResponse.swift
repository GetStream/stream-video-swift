//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// Response for ending a call
public final class EndCallResponse: @unchecked Sendable, Codable, JSONEncodable {
    /// Duration of the request in milliseconds
    public var duration: String

    public init(duration: String) {
        self.duration = duration
    }

    public enum CodingKeys: String, CodingKey {
        case duration
    }
}

extension EndCallResponse: Hashable {
    public static func == (lhs: EndCallResponse, rhs: EndCallResponse) -> Bool {
        lhs.duration == rhs.duration
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
    }
}
