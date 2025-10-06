//
//  AudioBitrateProfile.swift
//  DemoApp
//
//  Created by Ilias Pavlidakis on 6/10/25.
//

import Foundation

public enum AudioBitrateProfile: Int {
    case voiceStandard = 0
    case voiceHighQuality
    case musicHighQuality

    var source: Stream_Video_Sfu_Models_AudioBitrateProfile {
        switch self {
        case .voiceStandard:
            return .voiceStandardUnspecified
        case .voiceHighQuality:
            return .voiceHighQuality
        case .musicHighQuality:
            return .musicHighQuality
        }
    }

    init(_ source: Stream_Video_Sfu_Models_AudioBitrateProfile) {
        switch source {
        case .voiceStandardUnspecified:
            self = .voiceStandard
        case .voiceHighQuality:
            self = .voiceHighQuality
        case .musicHighQuality:
            self = .musicHighQuality
        case .UNRECOGNIZED:
            self = .voiceStandard
        }
    }
}
