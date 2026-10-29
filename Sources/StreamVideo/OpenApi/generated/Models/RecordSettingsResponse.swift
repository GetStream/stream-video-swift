//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// RecordSettings is the payload for recording settings
public final class RecordSettingsResponse: @unchecked Sendable, Codable, JSONEncodable {
    public var audioOnly: Bool
    public var mode: String
    public var quality: String

    public init(audioOnly: Bool, mode: String, quality: String) {
        self.audioOnly = audioOnly
        self.mode = mode
        self.quality = quality
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.audioOnly = try container.decode(Bool.self, forKey: .audioOnly)
        self.mode = try container.decode(String.self, forKey: .mode)
        self.quality = try container.decode(String.self, forKey: .quality)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(audioOnly, forKey: .audioOnly)
        try container.encode(mode, forKey: .mode)
        try container.encode(quality, forKey: .quality)
    }
}

extension RecordSettingsResponse: Hashable {
    public static func == (lhs: RecordSettingsResponse, rhs: RecordSettingsResponse) -> Bool {
        lhs.audioOnly == rhs.audioOnly &&
            lhs.mode == rhs.mode &&
            lhs.quality == rhs.quality
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(audioOnly)
        hasher.combine(mode)
        hasher.combine(quality)
    }
}
