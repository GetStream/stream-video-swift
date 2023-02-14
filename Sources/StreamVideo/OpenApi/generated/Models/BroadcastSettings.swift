//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct BroadcastSettings: Codable, JSONEncodable, Hashable {

    internal var enabled: Bool
    internal var hls: HLSSettings

    internal init(enabled: Bool, hls: HLSSettings) {
        self.enabled = enabled
        self.hls = hls
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case enabled
        case hls
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(enabled, forKey: .enabled)
        try container.encode(hls, forKey: .hls)
    }
}
