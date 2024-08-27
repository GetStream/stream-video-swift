//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct RTMPIngress: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var address: String

    public init(address: String) {
        self.address = address
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case address
    }
}
