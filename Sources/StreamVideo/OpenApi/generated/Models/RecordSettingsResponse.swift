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

    public enum CodingKeys: String, CodingKey {
        case audioOnly = "audio_only"
        case mode
        case quality
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
