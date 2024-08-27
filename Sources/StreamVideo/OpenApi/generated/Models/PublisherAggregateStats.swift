//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct PublisherAggregateStats: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var byTrackType: [String: Count]? = nil
    public var total: Count? = nil

    public init(byTrackType: [String: Count]? = nil, total: Count? = nil) {
        self.byTrackType = byTrackType
        self.total = total
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case byTrackType = "by_track_type"
        case total
    }
}
