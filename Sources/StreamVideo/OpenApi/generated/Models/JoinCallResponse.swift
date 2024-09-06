//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct JoinCallResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var call: CallResponse
    public var created: Bool
    public var credentials: Credentials
    public var duration: String
    public var members: [MemberResponse]
    public var membership: MemberResponse?
    public var ownCapabilities: [OwnCapability]
    public var statsOptions: StatsOptions

    public init(
        call: CallResponse,
        created: Bool,
        credentials: Credentials,
        duration: String,
        members: [MemberResponse],
        membership: MemberResponse? = nil,
        ownCapabilities: [OwnCapability],
        statsOptions: StatsOptions
    ) {
        self.call = call
        self.created = created
        self.credentials = credentials
        self.duration = duration
        self.members = members
        self.membership = membership
        self.ownCapabilities = ownCapabilities
        self.statsOptions = statsOptions
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case call
        case created
        case credentials
        case duration
        case members
        case membership
        case ownCapabilities = "own_capabilities"
        case statsOptions = "stats_options"
    }
}
