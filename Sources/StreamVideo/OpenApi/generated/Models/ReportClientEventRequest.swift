//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class ReportClientEventRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Client-side events to report (1-100 per request)
    public var events: [ClientEvent]

    public init(events: [ClientEvent]) {
        self.events = events
    }

public enum CodingKeys: String, CodingKey, CaseIterable {
    case events
}

    public static func == (lhs: ReportClientEventRequest, rhs: ReportClientEventRequest) -> Bool {
        lhs.events == rhs.events
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(events)
    }
}
