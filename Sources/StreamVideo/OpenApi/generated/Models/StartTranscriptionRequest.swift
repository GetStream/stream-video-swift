//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class StartTranscriptionRequest: @unchecked Sendable, Encodable, JSONEncodable {
    
    /// Enable closed captions along with transcriptions
    public var enableClosedCaptions: Bool?
    /// The spoken language in the call, if not provided the language defined in the transcription settings will be used. One of: auto, ar, bg, ca, cs, da, de, el, en, es, et, fi, fr, he, hi, hr, hu, id, it, ja, ko, ms, nl, no, pl, pt, ro, ru, sk, sl, sv, ta, th, tl, tr, uk, zh
    public var language: String?
    /// Store transcriptions in this external storage
    public var transcriptionExternalStorage: String?

    public init(enableClosedCaptions: Bool? = nil, language: String? = nil, transcriptionExternalStorage: String? = nil) {
        self.enableClosedCaptions = enableClosedCaptions
        self.language = language
        self.transcriptionExternalStorage = transcriptionExternalStorage
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(enableClosedCaptions, forKey: .enableClosedCaptions)
        try container.encodeIfPresent(language, forKey: .language)
        try container.encodeIfPresent(transcriptionExternalStorage, forKey: .transcriptionExternalStorage)
    }
}

extension StartTranscriptionRequest: Hashable {
    public static func == (lhs: StartTranscriptionRequest, rhs: StartTranscriptionRequest) -> Bool {
        lhs.enableClosedCaptions == rhs.enableClosedCaptions &&
            lhs.language == rhs.language &&
            lhs.transcriptionExternalStorage == rhs.transcriptionExternalStorage
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(enableClosedCaptions)
        hasher.combine(language)
        hasher.combine(transcriptionExternalStorage)
    }
}
