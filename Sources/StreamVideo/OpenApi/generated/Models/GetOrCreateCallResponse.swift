//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct GetOrCreateCallResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var call: CallResponse
    public var created: Bool
    public var duration: String
    public var members: [MemberResponse]
    public var membership: MemberResponse?
    public var ownCapabilities: [OwnCapability]

    public init(
        call: CallResponse,
        created: Bool,
        duration: String,
        members: [MemberResponse],
        membership: MemberResponse? = nil,
        ownCapabilities: [OwnCapability]
    ) {
        self.call = call
        self.created = created
        self.duration = duration
        self.members = members
        self.membership = membership
        self.ownCapabilities = ownCapabilities
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case call
        case created
        case duration
        case members
        case membership
        case ownCapabilities = "own_capabilities"
    }
}
