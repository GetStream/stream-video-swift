//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct CountrywiseAggregateStats: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var participantCount: Count?
    public var publisherJitter: Stats?
    public var publisherLatency: Stats?
    public var subscriberJitter: Stats?
    public var subscriberLatency: Stats?

    public init(
        participantCount: Count? = nil,
        publisherJitter: Stats? = nil,
        publisherLatency: Stats? = nil,
        subscriberJitter: Stats? = nil,
        subscriberLatency: Stats? = nil
    ) {
        self.participantCount = participantCount
        self.publisherJitter = publisherJitter
        self.publisherLatency = publisherLatency
        self.subscriberJitter = subscriberJitter
        self.subscriberLatency = subscriberLatency
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case participantCount = "participant_count"
        case publisherJitter = "publisher_jitter"
        case publisherLatency = "publisher_latency"
        case subscriberJitter = "subscriber_jitter"
        case subscriberLatency = "subscriber_latency"
    }
}
