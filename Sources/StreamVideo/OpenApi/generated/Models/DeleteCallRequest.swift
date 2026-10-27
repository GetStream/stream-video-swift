//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// DeleteCallRequest is the payload for deleting a call.
public final class DeleteCallRequest: @unchecked Sendable, Codable, JSONEncodable {
    /// if true the call will be hard deleted along with all related data
    public var hard: Bool?

    public init(hard: Bool? = nil) {
        self.hard = hard
    }

    public enum CodingKeys: String, CodingKey {
        case hard
    }
}

extension DeleteCallRequest: Hashable {
    public static func == (lhs: DeleteCallRequest, rhs: DeleteCallRequest) -> Bool {
        lhs.hard == rhs.hard
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(hard)
    }
}
