//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct JoinCallRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var create: Bool?
    public var data: CallRequest?
    public var location: String
    public var membersLimit: Int?
    public var migratingFrom: String?
    public var notify: Bool?
    public var ring: Bool?
    public var video: Bool?

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
