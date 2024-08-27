//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct QueryCallsResponse: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var calls: [CallStateResponseFields]
    public var duration: String
    public var next: String? = nil
    public var prev: String? = nil

    public init(calls: [CallStateResponseFields], duration: String, next: String? = nil, prev: String? = nil) {
        self.calls = calls
        self.duration = duration
        self.next = next
        self.prev = prev
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case calls
        case duration
        case next
        case prev
    }
}
