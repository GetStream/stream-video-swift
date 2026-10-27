//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class RejectCallRequest: @unchecked Sendable, Codable, JSONEncodable {
    /// Reason for rejecting the call
    public var reason: String?

    public init(reason: String? = nil) {
        self.reason = reason
    }

    public enum CodingKeys: String, CodingKey {
        case reason
    }
}

extension RejectCallRequest: Hashable {
    public static func == (lhs: RejectCallRequest, rhs: RejectCallRequest) -> Bool {
        lhs.reason == rhs.reason
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(reason)
    }
}
