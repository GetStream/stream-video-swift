//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class CallStatsReportSummaryResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var callCid: String
    public var callDurationSeconds: Int
    public var callSessionId: String
    public var callStatus: String
    public var createdAt: Date?
    public var firstStatsTime: Date
    public var minUserRating: Int?
    public var qualityScore: Int?

    public init(
        callCid: String,
        callDurationSeconds: Int,
        callSessionId: String,
        callStatus: String,
        createdAt: Date? = nil,
        firstStatsTime: Date,
        minUserRating: Int? = nil,
        qualityScore: Int? = nil
    ) {
        self.callCid = callCid
        self.callDurationSeconds = callDurationSeconds
        self.callSessionId = callSessionId
        self.callStatus = callStatus
        self.createdAt = createdAt
        self.firstStatsTime = firstStatsTime
        self.minUserRating = minUserRating
        self.qualityScore = qualityScore
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case callCid = "call_cid"
        case callDurationSeconds = "call_duration_seconds"
        case callSessionId = "call_session_id"
        case callStatus = "call_status"
        case createdAt = "created_at"
        case firstStatsTime = "first_stats_time"
        case minUserRating = "min_user_rating"
        case qualityScore = "quality_score"
    }
    
    public static func == (lhs: CallStatsReportSummaryResponse, rhs: CallStatsReportSummaryResponse) -> Bool {
        lhs.callCid == rhs.callCid &&
            lhs.callDurationSeconds == rhs.callDurationSeconds &&
            lhs.callSessionId == rhs.callSessionId &&
            lhs.callStatus == rhs.callStatus &&
            lhs.createdAt == rhs.createdAt &&
            lhs.firstStatsTime == rhs.firstStatsTime &&
            lhs.minUserRating == rhs.minUserRating &&
            lhs.qualityScore == rhs.qualityScore
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(callCid)
        hasher.combine(callDurationSeconds)
        hasher.combine(callSessionId)
        hasher.combine(callStatus)
        hasher.combine(createdAt)
        hasher.combine(firstStatsTime)
        hasher.combine(minUserRating)
        hasher.combine(qualityScore)
    }
}
