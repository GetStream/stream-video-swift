//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

#if compiler(>=6.0)
extension TranscriptionSettings.Mode: @retroactive CustomStringConvertible {}
extension TranscriptionSettings.ClosedCaptionMode: @retroactive CustomStringConvertible {}
extension TranscriptionSettings.Language: @retroactive CustomStringConvertible {}
#else
extension TranscriptionSettings.Mode: CustomStringConvertible {}
extension TranscriptionSettings.ClosedCaptionMode: CustomStringConvertible {}
extension TranscriptionSettings.Language: CustomStringConvertible {}
#endif

extension TranscriptionSettings.Mode {
    public var description: String {
        switch self {
        case .autoOn:
            return "auto-on"
        case .available:
            return "Available"
        case .disabled:
            return "Disabled"
        case .unknown:
            return "Unknown"
        }
    }
}

extension TranscriptionSettings.ClosedCaptionMode {
    public var description: String {
        switch self {
        case .autoOn:
            return "auto-on"
        case .available:
            return "Available"
        case .disabled:
            return "Disabled"
        case .unknown:
            return "Unknown"
        }
    }
}

extension TranscriptionSettings.Language {
    public var description: String {
        switch self {
        case .ar: return "Arabic"
        case .auto: return "Auto"
        case .ca: return "Catalan"
        case .cs: return "Czech"
        case .da: return "Danish"
        case .de: return "German"
        case .el: return "Greek"
        case .en: return "English"
        case .es: return "Spanish"
        case .fi: return "Finnish"
        case .fr: return "French"
        case .he: return "Hebrew"
        case .hi: return "Hindi"
        case .hr: return "Croatian"
        case .hu: return "Hungarian"
        case .id: return "Indonesian"
        case .it: return "Italian"
        case .ja: return "Japanese"
        case .ko: return "Korean"
        case .ms: return "Malay"
        case .nl: return "Dutch"
        case .no: return "Norwegian"
        case .pl: return "Polish"
        case .pt: return "Portuguese"
        case .ro: return "Romanian"
        case .ru: return "Russian"
        case .sv: return "Swedish"
        case .ta: return "Tamil"
        case .th: return "Thai"
        case .tl: return "Tagalog"
        case .tr: return "Turkish"
        case .uk: return "Ukrainian"
        case .zh: return "Chinese"
        case .unknown:
            return "Unknown"
        }
    }
}
