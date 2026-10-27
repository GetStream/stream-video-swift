//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class CallStatsReportSummaryResponse: @unchecked Sendable, Decodable {
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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.callCid = try container.decode(String.self, forKey: .callCid)
        self.callDurationSeconds = try container.decode(Int.self, forKey: .callDurationSeconds)
        self.callSessionId = try container.decode(String.self, forKey: .callSessionId)
        self.callStatus = try container.decode(String.self, forKey: .callStatus)
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        self.firstStatsTime = try container.decode(Date.self, forKey: .firstStatsTime)
        self.minUserRating = try container.decodeIfPresent(Int.self, forKey: .minUserRating)
        self.qualityScore = try container.decodeIfPresent(Int.self, forKey: .qualityScore)
    }
}

extension CallStatsReportSummaryResponse: Hashable {
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
