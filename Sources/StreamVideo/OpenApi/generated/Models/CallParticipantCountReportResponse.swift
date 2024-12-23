//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public final class CallParticipantCountReportResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var daily: [DailyAggregateCallParticipantCountReportResponse]

    public init(daily: [DailyAggregateCallParticipantCountReportResponse]) {
        self.daily = daily
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case daily
    }
    
    public static func == (lhs: CallParticipantCountReportResponse, rhs: CallParticipantCountReportResponse) -> Bool {
        lhs.daily == rhs.daily
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(daily)
    }
}
