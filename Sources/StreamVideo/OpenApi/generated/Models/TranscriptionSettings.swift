//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class TranscriptionSettingsClosedCaptionMode: RawRepresentable, Codable, CustomStringConvertible, Hashable, Sendable {
    public let rawValue: String

    public var description: String { rawValue }

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let autoOn = TranscriptionSettingsClosedCaptionMode(rawValue: "auto-on")
    public static let available = TranscriptionSettingsClosedCaptionMode(rawValue: "available")
    public static let disabled = TranscriptionSettingsClosedCaptionMode(rawValue: "disabled")
}

public final class TranscriptionSettingsLanguage: RawRepresentable, Codable, CustomStringConvertible, Hashable, Sendable {
    public let rawValue: String

    public var description: String { rawValue }

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let ar = TranscriptionSettingsLanguage(rawValue: "ar")
    public static let auto = TranscriptionSettingsLanguage(rawValue: "auto")
    public static let bg = TranscriptionSettingsLanguage(rawValue: "bg")
    public static let ca = TranscriptionSettingsLanguage(rawValue: "ca")
    public static let cs = TranscriptionSettingsLanguage(rawValue: "cs")
    public static let da = TranscriptionSettingsLanguage(rawValue: "da")
    public static let de = TranscriptionSettingsLanguage(rawValue: "de")
    public static let el = TranscriptionSettingsLanguage(rawValue: "el")
    public static let en = TranscriptionSettingsLanguage(rawValue: "en")
    public static let es = TranscriptionSettingsLanguage(rawValue: "es")
    public static let et = TranscriptionSettingsLanguage(rawValue: "et")
    public static let fi = TranscriptionSettingsLanguage(rawValue: "fi")
    public static let fr = TranscriptionSettingsLanguage(rawValue: "fr")
    public static let he = TranscriptionSettingsLanguage(rawValue: "he")
    public static let hi = TranscriptionSettingsLanguage(rawValue: "hi")
    public static let hr = TranscriptionSettingsLanguage(rawValue: "hr")
    public static let hu = TranscriptionSettingsLanguage(rawValue: "hu")
    public static let id = TranscriptionSettingsLanguage(rawValue: "id")
    public static let it = TranscriptionSettingsLanguage(rawValue: "it")
    public static let ja = TranscriptionSettingsLanguage(rawValue: "ja")
    public static let ko = TranscriptionSettingsLanguage(rawValue: "ko")
    public static let ms = TranscriptionSettingsLanguage(rawValue: "ms")
    public static let nl = TranscriptionSettingsLanguage(rawValue: "nl")
    public static let no = TranscriptionSettingsLanguage(rawValue: "no")
    public static let pl = TranscriptionSettingsLanguage(rawValue: "pl")
    public static let pt = TranscriptionSettingsLanguage(rawValue: "pt")
    public static let ro = TranscriptionSettingsLanguage(rawValue: "ro")
    public static let ru = TranscriptionSettingsLanguage(rawValue: "ru")
    public static let sk = TranscriptionSettingsLanguage(rawValue: "sk")
    public static let sl = TranscriptionSettingsLanguage(rawValue: "sl")
    public static let sv = TranscriptionSettingsLanguage(rawValue: "sv")
    public static let ta = TranscriptionSettingsLanguage(rawValue: "ta")
    public static let th = TranscriptionSettingsLanguage(rawValue: "th")
    public static let tl = TranscriptionSettingsLanguage(rawValue: "tl")
    public static let tr = TranscriptionSettingsLanguage(rawValue: "tr")
    public static let uk = TranscriptionSettingsLanguage(rawValue: "uk")
    public static let zh = TranscriptionSettingsLanguage(rawValue: "zh")
}

public final class TranscriptionSettingsMode: RawRepresentable, Codable, CustomStringConvertible, Hashable, Sendable {
    public let rawValue: String

    public var description: String { rawValue }

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let autoOn = TranscriptionSettingsMode(rawValue: "auto-on")
    public static let available = TranscriptionSettingsMode(rawValue: "available")
    public static let disabled = TranscriptionSettingsMode(rawValue: "disabled")
}

public final class TranscriptionSettings: @unchecked Sendable, Decodable {
    public var closedCaptionMode: TranscriptionSettingsClosedCaptionMode
    public var language: TranscriptionSettingsLanguage
    public var mode: TranscriptionSettingsMode

    public init(
        closedCaptionMode: TranscriptionSettingsClosedCaptionMode,
        language: TranscriptionSettingsLanguage,
        mode: TranscriptionSettingsMode
    ) {
        self.closedCaptionMode = closedCaptionMode
        self.language = language
        self.mode = mode
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.closedCaptionMode = try container.decode(TranscriptionSettingsClosedCaptionMode.self, forKey: .closedCaptionMode)
        self.language = try container.decode(TranscriptionSettingsLanguage.self, forKey: .language)
        self.mode = try container.decode(TranscriptionSettingsMode.self, forKey: .mode)
    }
}

extension TranscriptionSettings: Hashable {
    public static func == (lhs: TranscriptionSettings, rhs: TranscriptionSettings) -> Bool {
        lhs.closedCaptionMode == rhs.closedCaptionMode &&
            lhs.language == rhs.language &&
            lhs.mode == rhs.mode
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(closedCaptionMode)
        hasher.combine(language)
        hasher.combine(mode)
    }
}
