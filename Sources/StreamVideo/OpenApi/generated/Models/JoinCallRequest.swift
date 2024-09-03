//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct JoinCallRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var create: Bool? = nil
    public var data: CallRequest? = nil
    public var location: String
    public var membersLimit: Int? = nil
    public var migratingFrom: String? = nil
    public var notify: Bool? = nil
    public var ring: Bool? = nil
    public var video: Bool? = nil

    public init(
        create: Bool? = nil,
        data: CallRequest? = nil,
        location: String,
        membersLimit: Int? = nil,
        migratingFrom: String? = nil,
        notify: Bool? = nil,
        ring: Bool? = nil,
        video: Bool? = nil
    ) {
        self.create = create
        self.data = data
        self.location = location
        self.membersLimit = membersLimit
        self.migratingFrom = migratingFrom
        self.notify = notify
        self.ring = ring
        self.video = video
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case create
        case data
        case location
        case membersLimit = "members_limit"
        case migratingFrom = "migrating_from"
        case notify
        case ring
        case video
    }
}
