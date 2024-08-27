//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct CallStateResponseFields: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var call: CallResponse
    public var members: [MemberResponse]
    public var membership: MemberResponse? = nil
    public var ownCapabilities: [OwnCapability]

    public init(
        call: CallResponse,
        members: [MemberResponse],
        membership: MemberResponse? = nil,
        ownCapabilities: [OwnCapability]
    ) {
        
        self.call = call
        self.members = members
        self.membership = membership
        self.ownCapabilities = ownCapabilities
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case call
        case members
        case membership
        case ownCapabilities = "own_capabilities"
    }
}
