//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct RecordSettingsRequest: Codable, JSONEncodable, Hashable {

    internal var audioOnly: Bool?
    internal var mode: String?
    internal var quality: String?

    internal init(audioOnly: Bool? = nil, mode: String? = nil, quality: String? = nil) {
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
        try container.encodeIfPresent(audioOnly, forKey: .audioOnly)
        try container.encodeIfPresent(mode, forKey: .mode)
        try container.encodeIfPresent(quality, forKey: .quality)
    }
}
