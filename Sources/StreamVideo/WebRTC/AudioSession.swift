//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import WebRTC

actor AudioSession {
    
    func configure(
        _ configuration: RTCAudioSessionConfiguration = .default,
        callSettings: CallSettings
    ) {
        let audioSession: RTCAudioSession = RTCAudioSession.sharedInstance()
        audioSession.lockForConfiguration()

        defer { audioSession.unlockForConfiguration() }

        do {
            log.debug("Configuring audio session")
            try audioSession.setConfiguration(configuration, active: callSettings.audioOn)
            try audioSession.overrideOutputAudioPort(callSettings.speakerOn ? .speaker : .none)
        } catch {
            log.error("Error occured while configuring audio session \(error)")
        }
    }
}

extension RTCAudioSessionConfiguration {
    
    static let `default`: RTCAudioSessionConfiguration = {
        let configuration = RTCAudioSessionConfiguration.webRTC()
        configuration.mode = AVAudioSession.Mode.voiceChat.rawValue
        configuration.category = AVAudioSession.Category.playAndRecord.rawValue
        return configuration
    }()
}
