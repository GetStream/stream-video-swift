//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class TargetResolution: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var bitrate: Int?
    public var height: Int
    public var width: Int

    public init(bitrate: Int? = nil, height: Int, width: Int) {
        self.bitrate = bitrate
        self.height = height
        self.width = width
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case bitrate
        case height
        case width
    }
    
    public static func == (lhs: TargetResolution, rhs: TargetResolution) -> Bool {
        lhs.bitrate == rhs.bitrate &&
            lhs.height == rhs.height &&
            lhs.width == rhs.width
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(bitrate)
        hasher.combine(height)
        hasher.combine(width)
    }
}
