//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct GetCallStatsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var aggregated: AggregatedStats?
    public var callDurationSeconds: Int
    public var callStatus: String
    public var callTimeline: CallTimeline?
    public var duration: String
    public var jitter: Stats?
    public var latency: Stats?
    public var maxFreezesDurationSeconds: Int
    public var maxParticipants: Int
    public var maxTotalQualityLimitationDurationSeconds: Int
    public var participantReport: [UserStats?]
    public var publishingParticipants: Int
    public var qualityScore: Int
    public var sfuCount: Int
    public var sfus: [SFULocationResponse]

    public init(
        aggregated: AggregatedStats? = nil,
        callDurationSeconds: Int,
        callStatus: String,
        callTimeline: CallTimeline? = nil,
        duration: String,
        jitter: Stats? = nil,
        latency: Stats? = nil,
        maxFreezesDurationSeconds: Int,
        maxParticipants: Int,
        maxTotalQualityLimitationDurationSeconds: Int,
        participantReport: [UserStats?],
        publishingParticipants: Int,
        qualityScore: Int,
        sfuCount: Int,
        sfus: [SFULocationResponse]
    ) {
        self.aggregated = aggregated
        self.callDurationSeconds = callDurationSeconds
        self.callStatus = callStatus
        self.callTimeline = callTimeline
        self.duration = duration
        self.jitter = jitter
        self.latency = latency
        self.maxFreezesDurationSeconds = maxFreezesDurationSeconds
        self.maxParticipants = maxParticipants
        self.maxTotalQualityLimitationDurationSeconds = maxTotalQualityLimitationDurationSeconds
        self.participantReport = participantReport
        self.publishingParticipants = publishingParticipants
        self.qualityScore = qualityScore
        self.sfuCount = sfuCount
        self.sfus = sfus
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case aggregated
        case callDurationSeconds = "call_duration_seconds"
        case callStatus = "call_status"
        case callTimeline = "call_timeline"
        case duration
        case jitter
        case latency
        case maxFreezesDurationSeconds = "max_freezes_duration_seconds"
        case maxParticipants = "max_participants"
        case maxTotalQualityLimitationDurationSeconds = "max_total_quality_limitation_duration_seconds"
        case participantReport = "participant_report"
        case publishingParticipants = "publishing_participants"
        case qualityScore = "quality_score"
        case sfuCount = "sfu_count"
        case sfus
    }
}
