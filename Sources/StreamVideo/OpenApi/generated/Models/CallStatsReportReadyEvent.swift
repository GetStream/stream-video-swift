//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent when the insights report is ready
public final class CallStatsReportReadyEvent: Sendable, Event, Decodable, WSCallEvent {
    public let callCid: String
    public let createdAt: Date
    /// Call session ID
    public let sessionId: String
    /// The type of event, "call.report_ready" in this case
    public let type: String

    public init(callCid: String, createdAt: Date, sessionId: String, type: String = "call.stats_report_ready") {
        self.callCid = callCid
        self.createdAt = createdAt
        self.sessionId = sessionId
        self.type = type
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.callCid = try container.decode(String.self, forKey: .callCid)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.sessionId = try container.decode(String.self, forKey: .sessionId)
        self.type = try container.decode(String.self, forKey: .type)
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
