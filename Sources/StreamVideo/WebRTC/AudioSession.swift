//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import WebRTC

actor AudioSession {
    
    func configure(
        _ configuration: RTCAudioSessionConfiguration = .default,
        audioOn: Bool,
        speakerOn: Bool
    ) {
        let audioSession: RTCAudioSession = RTCAudioSession.sharedInstance()
        audioSession.lockForConfiguration()
        audioSession.useManualAudio = true
        audioSession.isAudioEnabled = true

        defer { audioSession.unlockForConfiguration() }

        do {
            log.debug("Configuring audio session")
            try audioSession.setConfiguration(configuration, active: audioOn)
            if speakerOn {
                configuration.categoryOptions.insert(.defaultToSpeaker)
                configuration.mode = AVAudioSession.Mode.videoChat.rawValue
            } else {
                configuration.categoryOptions.remove(.defaultToSpeaker)
                configuration.mode = AVAudioSession.Mode.voiceChat.rawValue
            }
        } catch {
            log.error("Error occured while configuring audio session", error: error)
        }
    }
    
    func setAudioSessionEnabled(_ enabled: Bool) {
        let audioSession: RTCAudioSession = RTCAudioSession.sharedInstance()
        audioSession.lockForConfiguration()

        defer { audioSession.unlockForConfiguration() }
        audioSession.isAudioEnabled = enabled
    }
    
}

extension RTCAudioSessionConfiguration {
    
    static let `default`: RTCAudioSessionConfiguration = {
        let configuration = RTCAudioSessionConfiguration.webRTC()
        var categoryOptions: AVAudioSession.CategoryOptions = [.allowBluetooth, .allowBluetoothA2DP]
        configuration.mode = AVAudioSession.Mode.videoChat.rawValue
        configuration.category = AVAudioSession.Category.playAndRecord.rawValue
        configuration.categoryOptions = categoryOptions
        return configuration
    }()
}
