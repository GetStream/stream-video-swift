//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct AggregatedStats: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var countrywiseAggregateStats: [String: CountrywiseAggregateStats?]? = nil
    public var publisherAggregateStats: PublisherAggregateStats? = nil
    public var turn: TURNAggregatedStats? = nil

    public init(
        countrywiseAggregateStats: [String: CountrywiseAggregateStats?]? = nil,
        publisherAggregateStats: PublisherAggregateStats? = nil,
        turn: TURNAggregatedStats? = nil
    ) {
        self.countrywiseAggregateStats = countrywiseAggregateStats
        self.publisherAggregateStats = publisherAggregateStats
        self.turn = turn
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case countrywiseAggregateStats = "countrywise_aggregate_stats"
        case publisherAggregateStats = "publisher_aggregate_stats"
        case turn
    }
}
