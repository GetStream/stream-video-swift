//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class BlockUserResponse: @unchecked Sendable, Decodable, Hashable {
    
    public var duration: String

    public init(duration: String) {
        self.duration = duration
    }
    
    public enum CodingKeys: String, CodingKey {
        case duration
    }
    
    public static func == (lhs: BlockUserResponse, rhs: BlockUserResponse) -> Bool {
        lhs.duration == rhs.duration
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
    }
}
