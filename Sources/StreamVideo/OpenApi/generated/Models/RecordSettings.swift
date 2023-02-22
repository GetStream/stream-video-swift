//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct RecordSettings: Codable, JSONEncodable, Hashable {

    internal var audioOnly: Bool
    internal var mode: String
    internal var quality: String

    internal init(audioOnly: Bool, mode: String, quality: String) {
        self.audioOnly = audioOnly
        self.mode = mode
        self.quality = quality
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case audioOnly = "audio_only"
        case mode
        case quality
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(audioOnly, forKey: .audioOnly)
        try container.encode(mode, forKey: .mode)
        try container.encode(quality, forKey: .quality)
    }
}
