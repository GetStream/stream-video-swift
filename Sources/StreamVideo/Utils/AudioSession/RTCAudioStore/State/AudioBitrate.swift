//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

public enum AudioBitrate: Hashable, Codable, Sendable {
    case voiceStandard
    case voiceHighQuality
    case musicHighQuality

    var rawValue: Int {
        switch self {
        case .voiceStandard:
            return 0
        case .voiceHighQuality:
            return 1
        case .musicHighQuality:
            return 2
        }
    }

    init(_ source: Stream_Video_Sfu_Models_AudioBitrateType) {
        switch source {
        case .voiceStandardUnspecified:
            self = .voiceStandard
        case .voiceHighQuality:
            self = .voiceHighQuality
        case .musicHighQuality:
            self = .musicHighQuality
        case let .UNRECOGNIZED(value):
            self = .voiceStandard
        }
    }
}

extension Stream_Video_Sfu_Models_AudioBitrateType {

    init(_ source: AudioBitrate) {
        switch source {
        case .voiceStandard:
            self = .voiceStandardUnspecified
        case .voiceHighQuality:
            self = .voiceHighQuality
        case .musicHighQuality:
            self = .musicHighQuality
        }
    }
}
