//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct CountrywiseAggregateStats: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var participantCount: Count? = nil
    public var publisherJitter: TimeStats? = nil
    public var publisherLatency: TimeStats? = nil
    public var subscriberJitter: TimeStats? = nil
    public var subscriberLatency: TimeStats? = nil

    public init(
        participantCount: Count? = nil,
        publisherJitter: TimeStats? = nil,
        publisherLatency: TimeStats? = nil,
        subscriberJitter: TimeStats? = nil,
        subscriberLatency: TimeStats? = nil
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
