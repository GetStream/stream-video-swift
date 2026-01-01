//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class RTMPIngress: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var address: String

    public init(address: String) {
        self.address = address
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case address
    }
    
    public static func == (lhs: RTMPIngress, rhs: RTMPIngress) -> Bool {
        lhs.address == rhs.address
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(address)
    }
}
