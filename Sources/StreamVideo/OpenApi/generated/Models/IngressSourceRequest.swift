//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class IngressSourceRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public enum IngressSourceRequestFps: String, Sendable, Codable, CaseIterable {
        case _30 = "30"
        case _60 = "60"
        case unknown = "_unknown"

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let decodedValue = try? container.decode(String.self),
                let value = Self(rawValue: decodedValue) {
                self = value
            } else {
                self = .unknown
            }
        }
    }
    public var fps: IngressSourceRequestFps
    public var height: Int
    public var width: Int

    public init(fps: IngressSourceRequestFps, height: Int, width: Int) {
        self.fps = fps
        self.height = height
        self.width = width
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case fps
        case height
        case width
    }

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
