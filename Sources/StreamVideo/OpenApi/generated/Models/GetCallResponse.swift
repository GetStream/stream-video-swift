//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct GetCallResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var call: CallResponse
    public var duration: String
    public var members: [MemberResponse]
    public var membership: MemberResponse? = nil
    public var ownCapabilities: [OwnCapability]

    public init(
        call: CallResponse,
        duration: String,
        members: [MemberResponse],
        membership: MemberResponse? = nil,
        ownCapabilities: [OwnCapability]
    ) {
        self.call = call
        self.duration = duration
        self.members = members
        self.membership = membership
        self.ownCapabilities = ownCapabilities
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case call
        case duration
        case members
        case membership
        case ownCapabilities = "own_capabilities"
    }
}
