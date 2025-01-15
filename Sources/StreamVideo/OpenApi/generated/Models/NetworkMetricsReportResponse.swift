//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

public final class NetworkMetricsReportResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var averageConnectionTime: Float?
    public var averageJitter: Float?
    public var averageLatency: Float?
    public var averageTimeToReconnect: Float?

    public init(
        averageConnectionTime: Float? = nil,
        averageJitter: Float? = nil,
        averageLatency: Float? = nil,
        averageTimeToReconnect: Float? = nil
    ) {
        self.averageConnectionTime = averageConnectionTime
        self.averageJitter = averageJitter
        self.averageLatency = averageLatency
        self.averageTimeToReconnect = averageTimeToReconnect
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case averageConnectionTime = "average_connection_time"
        case averageJitter = "average_jitter"
        case averageLatency = "average_latency"
        case averageTimeToReconnect = "average_time_to_reconnect"
    }
    
    public static func == (lhs: NetworkMetricsReportResponse, rhs: NetworkMetricsReportResponse) -> Bool {
        lhs.averageConnectionTime == rhs.averageConnectionTime &&
            lhs.averageJitter == rhs.averageJitter &&
            lhs.averageLatency == rhs.averageLatency &&
            lhs.averageTimeToReconnect == rhs.averageTimeToReconnect
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(averageConnectionTime)
        hasher.combine(averageJitter)
        hasher.combine(averageLatency)
        hasher.combine(averageTimeToReconnect)
    }
}
