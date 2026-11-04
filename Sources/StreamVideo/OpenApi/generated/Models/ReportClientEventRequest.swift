//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// Reports a batch of client-side telemetry events. Each event is validated and processed independently; one invalid event does not block the rest of the batch.
public final class ReportClientEventRequest: @unchecked Sendable, Encodable, JSONEncodable {
    /// Client-side events to report (1-100 per request)
    public var events: [ClientEvent]

    public init(events: [ClientEvent]) {
        self.events = events
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(events, forKey: .events)
    }
}

extension ReportClientEventRequest: Hashable {
    public static func == (lhs: ReportClientEventRequest, rhs: ReportClientEventRequest) -> Bool {
        lhs.events == rhs.events
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(events)
    }
}
