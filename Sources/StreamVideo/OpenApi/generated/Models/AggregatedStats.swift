//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class AggregatedStats: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var countrywiseAggregateStats: [String: CountrywiseAggregateStats?]?
    public var publisherAggregateStats: PublisherAggregateStats?
    public var turn: TURNAggregatedStats?

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
    
    public static func == (lhs: AggregatedStats, rhs: AggregatedStats) -> Bool {
        lhs.countrywiseAggregateStats == rhs.countrywiseAggregateStats &&
            lhs.publisherAggregateStats == rhs.publisherAggregateStats &&
            lhs.turn == rhs.turn
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(countrywiseAggregateStats)
        hasher.combine(publisherAggregateStats)
        hasher.combine(turn)
    }
}
