//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class GetEdgesResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var duration: String
    public var edges: [EdgeResponse]

    public init(duration: String, edges: [EdgeResponse]) {
        self.duration = duration
        self.edges = edges
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case edges
    }
    
    public static func == (lhs: GetEdgesResponse, rhs: GetEdgesResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.edges == rhs.edges
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(edges)
    }
}
