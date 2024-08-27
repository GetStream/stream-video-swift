//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct CreateGuestRequest: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var user: UserRequest

    public init(user: UserRequest) {
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case user
    }
}
