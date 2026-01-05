//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class VideoResolution: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var height: Int
    public var width: Int

    public init(height: Int, width: Int) {
        self.height = height
        self.width = width
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case height
        case width
    }
    
    public static func == (lhs: VideoResolution, rhs: VideoResolution) -> Bool {
        lhs.height == rhs.height &&
            lhs.width == rhs.width
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(height)
        hasher.combine(width)
    }
}
