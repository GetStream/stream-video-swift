//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class TargetResolution: @unchecked Sendable, Codable, JSONEncodable {
    public var bitrate: Int?
    public var height: Int
    public var width: Int

    public init(bitrate: Int? = nil, height: Int, width: Int) {
        self.bitrate = bitrate
        self.height = height
        self.width = width
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.bitrate = try container.decodeIfPresent(Int.self, forKey: .bitrate)
        self.height = try container.decode(Int.self, forKey: .height)
        self.width = try container.decode(Int.self, forKey: .width)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(bitrate, forKey: .bitrate)
        try container.encode(height, forKey: .height)
        try container.encode(width, forKey: .width)
    }
}

extension TargetResolution: Hashable {
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
