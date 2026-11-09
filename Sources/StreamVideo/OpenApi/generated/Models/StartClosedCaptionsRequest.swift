//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class StartClosedCaptionsRequest: Sendable, Encodable, JSONEncodable {
    
    /// Enable transcriptions along with closed captions
    public let enableTranscription: Bool?
    /// Which external storage to use for transcriptions (only applicable if enable_transcription is true)
    public let externalStorage: String?
    /// The spoken language in the call, if not provided the language defined in the transcription settings will be used. One of: auto, ar, bg, ca, cs, da, de, el, en, es, et, fi, fr, he, hi, hr, hu, id, it, ja, ko, ms, nl, no, pl, pt, ro, ru, sk, sl, sv, ta, th, tl, tr, uk, zh
    public let language: String?

    public init(enableTranscription: Bool? = nil, externalStorage: String? = nil, language: String? = nil) {
        self.enableTranscription = enableTranscription
        self.externalStorage = externalStorage
        self.language = language
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(enableTranscription, forKey: .enableTranscription)
        try container.encodeIfPresent(externalStorage, forKey: .externalStorage)
        try container.encodeIfPresent(language, forKey: .language)
    }
}

extension StartClosedCaptionsRequest: Hashable {
    public static func == (lhs: StartClosedCaptionsRequest, rhs: StartClosedCaptionsRequest) -> Bool {
        lhs.enableTranscription == rhs.enableTranscription &&
            lhs.externalStorage == rhs.externalStorage &&
            lhs.language == rhs.language
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(enableTranscription)
        hasher.combine(externalStorage)
        hasher.combine(language)
    }
}
