//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension RTCAudioStore.State {

    public struct InputConfiguration: Equatable, Encodable {
        public enum InputType: Equatable, Encodable { case mono, stereo }

        public var inputType: InputType
        public var audioBitrate: AudioBitrate
        public var audioProcessingEnabled: Bool

        var preferredNumberOfChannels: Int { inputType == .stereo ? 2 : 1 }

        init(_ audioBitrate: AudioBitrate) {
            switch audioBitrate {
            case .musicHighQuality:
                inputType = .stereo
                self.audioBitrate = audioBitrate
                audioProcessingEnabled = true
            default:
                inputType = .mono
                self.audioBitrate = audioBitrate
                audioProcessingEnabled = false
            }
        }

        nonisolated(unsafe) static let initial = InputConfiguration(.voiceStandard)
    }
}
