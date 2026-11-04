//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent when the insights report is ready
public final class CallStatsReportReadyEvent: @unchecked Sendable, Event, Codable, JSONEncodable, WSCallEvent {
    public var callCid: String
    public var createdAt: Date
    /// Call session ID
    public var sessionId: String
    /// The type of event, "call.report_ready" in this case
    public var type: String = "call.stats_report_ready"

    public init(callCid: String, createdAt: Date, sessionId: String) {
        self.callCid = callCid
        self.createdAt = createdAt
        self.sessionId = sessionId
    }

    public enum CodingKeys: String, CodingKey {
        case callCid = "call_cid"
        case createdAt = "created_at"
        case sessionId = "session_id"
        case type
    }
}

extension CallStatsReportReadyEvent: Hashable {
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
