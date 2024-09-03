//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct UpdateCallMembersRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var removeMembers: [String]? = nil
    public var updateMembers: [MemberRequest]? = nil

    public init(removeMembers: [String]? = nil, updateMembers: [MemberRequest]? = nil) {
        self.removeMembers = removeMembers
        self.updateMembers = updateMembers
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case removeMembers = "remove_members"
        case updateMembers = "update_members"
    }
}
