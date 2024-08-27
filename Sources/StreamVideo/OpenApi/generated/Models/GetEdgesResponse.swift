//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct GetEdgesResponse: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
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
}
