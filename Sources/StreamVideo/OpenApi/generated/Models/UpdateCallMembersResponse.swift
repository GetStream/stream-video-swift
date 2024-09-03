//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct UpdateCallMembersResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var duration: String
    public var members: [MemberResponse]

    public init(duration: String, members: [MemberResponse]) {
        self.duration = duration
        self.members = members
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case members
    }
}
