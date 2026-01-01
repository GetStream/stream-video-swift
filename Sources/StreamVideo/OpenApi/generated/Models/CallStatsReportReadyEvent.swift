//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class CallStatsReportReadyEvent: @unchecked Sendable,  Event, Codable, JSONEncodable, Hashable, WSCallEvent {
    public var callCid: String
    public var createdAt: Date
    public var sessionId: String
    public var type: String = "call.stats_report_ready"

    public init(callCid: String, createdAt: Date, sessionId: String) {
        self.callCid = callCid
        self.createdAt = createdAt
        self.sessionId = sessionId
    }

public enum CodingKeys: String, CodingKey, CaseIterable {
    case callCid = "call_cid"
    case createdAt = "created_at"
    case sessionId = "session_id"
    case type
}

    public static func == (lhs: CallStatsReportReadyEvent, rhs: CallStatsReportReadyEvent) -> Bool {
        lhs.callCid == rhs.callCid &&
        lhs.createdAt == rhs.createdAt &&
        lhs.sessionId == rhs.sessionId &&
        lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(callCid)
        hasher.combine(createdAt)
        hasher.combine(sessionId)
        hasher.combine(type)
    }
}
