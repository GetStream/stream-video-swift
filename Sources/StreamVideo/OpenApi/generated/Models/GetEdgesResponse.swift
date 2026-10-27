//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// Basic response information
public final class GetEdgesResponse: @unchecked Sendable, Codable, JSONEncodable {
    /// Duration of the request in milliseconds
    public var duration: String
    public var edges: [EdgeResponse]

    public init(duration: String, edges: [EdgeResponse]) {
        self.duration = duration
        self.edges = edges
    }

    public enum CodingKeys: String, CodingKey {
        case duration
        case edges
    }
}

extension GetEdgesResponse: Hashable {
    public static func == (lhs: GetEdgesResponse, rhs: GetEdgesResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.edges == rhs.edges
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(edges)
    }
}
