//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// Basic response information
public final class CollectUserFeedbackResponse: @unchecked Sendable, Decodable {
    /// Duration of the request in milliseconds
    public var duration: String

    public init(duration: String) {
        self.duration = duration
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.duration = try container.decode(String.self, forKey: .duration)
    }
}

extension CollectUserFeedbackResponse: Hashable {
    public static func == (lhs: CollectUserFeedbackResponse, rhs: CollectUserFeedbackResponse) -> Bool {
        lhs.duration == rhs.duration
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
    }
}
