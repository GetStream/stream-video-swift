//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct CallStatsReportSummaryResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var callCid: String
    public var callDurationSeconds: Int
    public var callSessionId: String
    public var callStatus: String
    public var createdAt: Date? = nil
    public var firstStatsTime: Date
    public var qualityScore: Int? = nil

    public init(
        callCid: String,
        callDurationSeconds: Int,
        callSessionId: String,
        callStatus: String,
        createdAt: Date? = nil,
        firstStatsTime: Date,
        qualityScore: Int? = nil
    ) {
        self.callCid = callCid
        self.callDurationSeconds = callDurationSeconds
        self.callSessionId = callSessionId
        self.callStatus = callStatus
        self.createdAt = createdAt
        self.firstStatsTime = firstStatsTime
        self.qualityScore = qualityScore
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case callCid = "call_cid"
        case callDurationSeconds = "call_duration_seconds"
        case callSessionId = "call_session_id"
        case callStatus = "call_status"
        case createdAt = "created_at"
        case firstStatsTime = "first_stats_time"
        case qualityScore = "quality_score"
    }
}
