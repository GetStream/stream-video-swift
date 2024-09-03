//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct CallTimeline: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var events: [CallEvent?]

    public init(events: [CallEvent?]) {
        self.events = events
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case events
    }
}
