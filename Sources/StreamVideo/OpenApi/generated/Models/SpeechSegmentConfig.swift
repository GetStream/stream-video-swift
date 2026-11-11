//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class SpeechSegmentConfig: Sendable, Codable, JSONEncodable {
    public let maxSpeechCaptionMs: Int?
    public let silenceDurationMs: Int?

    public init(maxSpeechCaptionMs: Int? = nil, silenceDurationMs: Int? = nil) {
        self.maxSpeechCaptionMs = maxSpeechCaptionMs
        self.silenceDurationMs = silenceDurationMs
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.maxSpeechCaptionMs = try container.decodeIfPresent(Int.self, forKey: .maxSpeechCaptionMs)
        self.silenceDurationMs = try container.decodeIfPresent(Int.self, forKey: .silenceDurationMs)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(maxSpeechCaptionMs, forKey: .maxSpeechCaptionMs)
        try container.encodeIfPresent(silenceDurationMs, forKey: .silenceDurationMs)
    }
}

extension SpeechSegmentConfig: Hashable {
    public static func == (lhs: SpeechSegmentConfig, rhs: SpeechSegmentConfig) -> Bool {
        lhs.maxSpeechCaptionMs == rhs.maxSpeechCaptionMs &&
            lhs.silenceDurationMs == rhs.silenceDurationMs
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(maxSpeechCaptionMs)
        hasher.combine(silenceDurationMs)
    }
}
