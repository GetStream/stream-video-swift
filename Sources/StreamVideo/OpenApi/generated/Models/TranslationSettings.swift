//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class TranslationSettings: @unchecked Sendable, Codable, JSONEncodable {
    public var enabled: Bool?
    public var languages: [String]?

    public init(enabled: Bool? = nil, languages: [String]? = nil) {
        self.enabled = enabled
        self.languages = languages
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled)
        self.languages = try container.decodeIfPresent([String].self, forKey: .languages)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(enabled, forKey: .enabled)
        try container.encodeIfPresent(languages, forKey: .languages)
    }
}

extension TranslationSettings: Hashable {
    public static func == (lhs: TranslationSettings, rhs: TranslationSettings) -> Bool {
        lhs.enabled == rhs.enabled &&
            lhs.languages == rhs.languages
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(enabled)
        hasher.combine(languages)
    }
}
