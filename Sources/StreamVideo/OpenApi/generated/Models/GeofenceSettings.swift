//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class GeofenceSettings: @unchecked Sendable, Decodable {
    public var names: [String]

    public init(names: [String]) {
        self.names = names
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.names = try container.decode([String].self, forKey: .names)
    }
}

extension GeofenceSettings: Hashable {
    public static func == (lhs: GeofenceSettings, rhs: GeofenceSettings) -> Bool {
        lhs.names == rhs.names
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(names)
    }
}
