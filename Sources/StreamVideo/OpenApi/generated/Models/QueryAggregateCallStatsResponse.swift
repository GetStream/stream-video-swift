//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public final class QueryAggregateCallStatsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var callDurationReport: CallDurationReportResponse?
    public var callParticipantCountReport: CallParticipantCountReportResponse?
    public var callsPerDayReport: CallsPerDayReportResponse?
    public var duration: String
    public var networkMetricsReport: NetworkMetricsReportResponse?
    public var qualityScoreReport: QualityScoreReportResponse?
    public var sdkUsageReport: SDKUsageReportResponse?
    public var userFeedbackReport: UserFeedbackReportResponse?

    public init(
        callDurationReport: CallDurationReportResponse? = nil,
        callParticipantCountReport: CallParticipantCountReportResponse? = nil,
        callsPerDayReport: CallsPerDayReportResponse? = nil,
        duration: String,
        networkMetricsReport: NetworkMetricsReportResponse? = nil,
        qualityScoreReport: QualityScoreReportResponse? = nil,
        sdkUsageReport: SDKUsageReportResponse? = nil,
        userFeedbackReport: UserFeedbackReportResponse? = nil
    ) {
        self.callDurationReport = callDurationReport
        self.callParticipantCountReport = callParticipantCountReport
        self.callsPerDayReport = callsPerDayReport
        self.duration = duration
        self.networkMetricsReport = networkMetricsReport
        self.qualityScoreReport = qualityScoreReport
        self.sdkUsageReport = sdkUsageReport
        self.userFeedbackReport = userFeedbackReport
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case callDurationReport = "call_duration_report"
        case callParticipantCountReport = "call_participant_count_report"
        case callsPerDayReport = "calls_per_day_report"
        case duration
        case networkMetricsReport = "network_metrics_report"
        case qualityScoreReport = "quality_score_report"
        case sdkUsageReport = "sdk_usage_report"
        case userFeedbackReport = "user_feedback_report"
    }
    
    public static func == (lhs: QueryAggregateCallStatsResponse, rhs: QueryAggregateCallStatsResponse) -> Bool {
        lhs.callDurationReport == rhs.callDurationReport &&
            lhs.callParticipantCountReport == rhs.callParticipantCountReport &&
            lhs.callsPerDayReport == rhs.callsPerDayReport &&
            lhs.duration == rhs.duration &&
            lhs.networkMetricsReport == rhs.networkMetricsReport &&
            lhs.qualityScoreReport == rhs.qualityScoreReport &&
            lhs.sdkUsageReport == rhs.sdkUsageReport &&
            lhs.userFeedbackReport == rhs.userFeedbackReport
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(callDurationReport)
        hasher.combine(callParticipantCountReport)
        hasher.combine(callsPerDayReport)
        hasher.combine(duration)
        hasher.combine(networkMetricsReport)
        hasher.combine(qualityScoreReport)
        hasher.combine(sdkUsageReport)
        hasher.combine(userFeedbackReport)
    }
}
