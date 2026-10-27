//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// This event is sent when call closed captions has failed
public final class CallClosedCaptionsFailedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, WSCallEvent {
    public var callCid: String
    public var createdAt: Date
    /// The type of event: "call.closed_captions_failed" in this case
    public var type: String = "call.closed_captions_failed"

    public init(callCid: String, createdAt: Date) {
        self.callCid = callCid
        self.createdAt = createdAt
    }

    public enum CodingKeys: String, CodingKey {
        case callCid = "call_cid"
        case createdAt = "created_at"
        case type
    }
}

extension CallClosedCaptionsFailedEvent: Hashable {
    public static func == (lhs: CallClosedCaptionsFailedEvent, rhs: CallClosedCaptionsFailedEvent) -> Bool {
        lhs.callCid == rhs.callCid &&
            lhs.createdAt == rhs.createdAt &&
            lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(callCid)
        hasher.combine(createdAt)
        hasher.combine(type)
    }
}
