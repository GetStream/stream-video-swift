//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class IngressSourceResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    public var fps: Int
    public var height: Int
    public var width: Int

    public init(fps: Int, height: Int, width: Int) {
        self.fps = fps
        self.height = height
        self.width = width
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case fps
        case height
        case width
    }

    public static func == (lhs: IngressSourceResponse, rhs: IngressSourceResponse) -> Bool {
        lhs.fps == rhs.fps &&
        lhs.height == rhs.height &&
        lhs.width == rhs.width
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(fps)
        hasher.combine(height)
        hasher.combine(width)
    }
}
