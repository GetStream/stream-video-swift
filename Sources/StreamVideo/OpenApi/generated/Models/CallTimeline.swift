//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class CallTimeline: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var events: [CallEvent]

    public init(events: [CallEvent]) {
        self.events = events
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case events
    }
    
    public static func == (lhs: CallTimeline, rhs: CallTimeline) -> Bool {
        lhs.events == rhs.events
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(events)
    }
}
