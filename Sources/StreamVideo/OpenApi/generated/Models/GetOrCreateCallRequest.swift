//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct GetOrCreateCallRequest: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var data: CallRequest? = nil
    public var membersLimit: Int? = nil
    public var notify: Bool? = nil
    public var ring: Bool? = nil
    public var video: Bool? = nil

    public init(data: CallRequest? = nil, membersLimit: Int? = nil, notify: Bool? = nil, ring: Bool? = nil, video: Bool? = nil) {
        self.data = data
        self.membersLimit = membersLimit
        self.notify = notify
        self.ring = ring
        self.video = video
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case data
        case membersLimit = "members_limit"
        case notify
        case ring
        case video
    }
}
