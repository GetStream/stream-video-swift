//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class IngressSourceResponse: @unchecked Sendable, Decodable {
    public var fps: Int
    public var height: Int
    public var width: Int

    public init(fps: Int, height: Int, width: Int) {
        self.fps = fps
        self.height = height
        self.width = width
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.fps = try container.decode(Int.self, forKey: .fps)
        self.height = try container.decode(Int.self, forKey: .height)
        self.width = try container.decode(Int.self, forKey: .width)
    }
}

extension IngressSourceResponse: Hashable {
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
