//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct QueryMembersResponse: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var duration: String
    public var members: [MemberResponse]
    public var next: String? = nil
    public var prev: String? = nil

    public init(duration: String, members: [MemberResponse], next: String? = nil, prev: String? = nil) {
        self.duration = duration
        self.members = members
        self.next = next
        self.prev = prev
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case members
        case next
        case prev
    }
}
