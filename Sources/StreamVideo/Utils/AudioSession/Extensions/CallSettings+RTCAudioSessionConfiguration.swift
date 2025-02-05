//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
import StreamWebRTC

extension CallSettings {

    var audioSessionConfiguration: RTCAudioSessionConfiguration {
        let category: AVAudioSession.Category = audioOn == true
            || speakerOn == true
            || videoOn == true
            ? .playAndRecord
            : .playback

        let mode: AVAudioSession.Mode = category == .playAndRecord
            ? speakerOn == true ? .videoChat : .voiceChat
            : .default

        let categoryOptions: AVAudioSession.CategoryOptions = category == .playAndRecord
            ? .playAndRecord
            : .playback

        let result = RTCAudioSessionConfiguration.webRTC()
        result.category = category.rawValue
        result.mode = mode.rawValue
        result.categoryOptions = categoryOptions

        return result
    }
}

extension RTCAudioSessionConfiguration: @unchecked Sendable {

    override open var description: String {
        [
            "RTCAudioSessionConfiguration",
            "(",
            [
                "category:\(AVAudioSession.Category(rawValue: category))",
                "mode:\(AVAudioSession.Mode(rawValue: mode))",
                "categoryOptions:\(categoryOptions)"
            ].joined(separator: ", "),
            ")"
        ].joined()
    }
}
