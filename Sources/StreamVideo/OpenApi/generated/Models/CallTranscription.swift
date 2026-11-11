//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// CallTranscription represents a transcription of a call.
public final class CallTranscription: @unchecked Sendable, Decodable {
    public var endTime: Date
    public var filename: String
    public var language: String?
    public var sessionId: String
    public var startTime: Date
    public var translated: Bool?
    public var url: String

    public init(
        endTime: Date,
        filename: String,
        language: String? = nil,
        sessionId: String,
        startTime: Date,
        translated: Bool? = nil,
        url: String
    ) {
        self.endTime = endTime
        self.filename = filename
        self.language = language
        self.sessionId = sessionId
        self.startTime = startTime
        self.translated = translated
        self.url = url
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.endTime = try container.decode(Date.self, forKey: .endTime)
        self.filename = try container.decode(String.self, forKey: .filename)
        self.language = try container.decodeIfPresent(String.self, forKey: .language)
        self.sessionId = try container.decode(String.self, forKey: .sessionId)
        self.startTime = try container.decode(Date.self, forKey: .startTime)
        self.translated = try container.decodeIfPresent(Bool.self, forKey: .translated)
        self.url = try container.decode(String.self, forKey: .url)
    }
}

extension CallTranscription: Hashable {
    public static func == (lhs: CallTranscription, rhs: CallTranscription) -> Bool {
        lhs.endTime == rhs.endTime &&
            lhs.filename == rhs.filename &&
            lhs.language == rhs.language &&
            lhs.sessionId == rhs.sessionId &&
            lhs.startTime == rhs.startTime &&
            lhs.translated == rhs.translated &&
            lhs.url == rhs.url
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(endTime)
        hasher.combine(filename)
        hasher.combine(language)
        hasher.combine(sessionId)
        hasher.combine(startTime)
        hasher.combine(translated)
        hasher.combine(url)
    }
}
