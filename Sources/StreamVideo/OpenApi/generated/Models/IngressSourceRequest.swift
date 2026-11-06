//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class IngressSourceRequest: Sendable, Encodable, JSONEncodable {
    public let fps: Int
    public let height: Int
    public let width: Int

    public init(fps: Int, height: Int, width: Int) {
        self.fps = fps
        self.height = height
        self.width = width
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(fps, forKey: .fps)
        try container.encode(height, forKey: .height)
        try container.encode(width, forKey: .width)
    }
}

extension IngressSourceRequest: Hashable {
    public static func == (lhs: IngressSourceRequest, rhs: IngressSourceRequest) -> Bool {
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
