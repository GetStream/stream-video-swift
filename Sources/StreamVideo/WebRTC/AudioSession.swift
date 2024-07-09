//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

actor AudioSession {
    
    private let rtcAudioSession: RTCAudioSession = RTCAudioSession.sharedInstance()

    func configure(
        _ configuration: RTCAudioSessionConfiguration = .default,
        audioOn: Bool,
        speakerOn: Bool
    ) {
        rtcAudioSession.lockForConfiguration()
        defer { rtcAudioSession.unlockForConfiguration() }
        rtcAudioSession.useManualAudio = true
        rtcAudioSession.isAudioEnabled = true

        do {
            log.debug("Configuring audio session")
            if speakerOn {
                configuration.categoryOptions.insert(.defaultToSpeaker)
                configuration.mode = AVAudioSession.Mode.videoChat.rawValue
            } else {
                configuration.categoryOptions.remove(.defaultToSpeaker)
                configuration.mode = AVAudioSession.Mode.voiceChat.rawValue
            }
            try rtcAudioSession.setConfiguration(configuration, active: audioOn)
        } catch {
            log.error("Error occured while configuring audio session", error: error)
        }
    }
    
    func setAudioSessionEnabled(_ enabled: Bool) {
        rtcAudioSession.lockForConfiguration()
        defer { rtcAudioSession.unlockForConfiguration() }
        rtcAudioSession.isAudioEnabled = enabled
    }

    deinit {
        cleanup()
    }
    
    nonisolated private func cleanup() {
        RTCAudioSession.sharedInstance().lockForConfiguration()
        RTCAudioSession.sharedInstance().isAudioEnabled = false
        RTCAudioSession.sharedInstance().unlockForConfiguration()
    }
}

extension RTCAudioSessionConfiguration: @unchecked Sendable {
    
    static let `default`: RTCAudioSessionConfiguration = {
        let configuration = RTCAudioSessionConfiguration.webRTC()
        var categoryOptions: AVAudioSession.CategoryOptions = [.allowBluetooth, .allowBluetoothA2DP]
        configuration.mode = AVAudioSession.Mode.videoChat.rawValue
        configuration.category = AVAudioSession.Category.playAndRecord.rawValue
        configuration.categoryOptions = categoryOptions
        return configuration
    }()
}
