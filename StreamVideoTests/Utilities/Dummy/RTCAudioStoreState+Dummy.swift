//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
@testable import StreamVideo

extension RTCAudioStore.StoreState.AudioRoute {

    static func dummy(
        inputs: [RTCAudioStore.StoreState.AudioRoute.Port] = [],
        outputs: [RTCAudioStore.StoreState.AudioRoute.Port] = [],
        reason: AVAudioSession.RouteChangeReason = .unknown
    ) -> RTCAudioStore.StoreState.AudioRoute {
        .init(
            inputs: inputs,
            outputs: outputs,
            reason: reason
        )
    }
}

extension RTCAudioStore.StoreState.AudioRoute.Port {

    static func dummy(
        type: String = .unique,
        name: String = .unique,
        id: String = .unique,
        isExternal: Bool = false,
        isSpeaker: Bool = false,
        isReceiver: Bool = false,
        channels: Int = 0
    ) -> RTCAudioStore.StoreState.AudioRoute.Port {
        .init(
            type: type,
            name: name,
            id: id,
            isExternal: isExternal,
            isSpeaker: isSpeaker,
            isReceiver: isReceiver,
            channels: channels
        )
    }
}

extension RTCAudioStore.StoreState.AVAudioSessionConfiguration {

    static func dummy(
        category: AVAudioSession.Category = .soloAmbient,
        mode: AVAudioSession.Mode = .default,
        options: AVAudioSession.CategoryOptions = [],
        overrideOutputAudioPort: AVAudioSession.PortOverride = .none
    ) -> RTCAudioStore.StoreState.AVAudioSessionConfiguration {
        .init(
            category: category,
            mode: mode,
            options: options,
            overrideOutputAudioPort: overrideOutputAudioPort
        )
    }
}

extension RTCAudioStore.StoreState.WebRTCAudioSessionConfiguration {

    static func dummy(
        isAudioEnabled: Bool = false,
        useManualAudio: Bool = false,
        prefersNoInterruptionsFromSystemAlerts: Bool = false
    ) -> RTCAudioStore.StoreState.WebRTCAudioSessionConfiguration {
        .init(
            isAudioEnabled: isAudioEnabled,
            useManualAudio: useManualAudio,
            prefersNoInterruptionsFromSystemAlerts: prefersNoInterruptionsFromSystemAlerts
        )
    }
}

extension RTCAudioStore.StoreState.StereoConfiguration {

    static func dummy(
        playout: RTCAudioStore.StoreState.StereoConfiguration.Playout = .dummy()
    ) -> RTCAudioStore.StoreState.StereoConfiguration {
        .init(
            playout: playout
        )
    }
}

extension RTCAudioStore.StoreState.StereoConfiguration.Playout {

    static func dummy(
        preferred: Bool = false,
        enabled: Bool = false
    ) -> RTCAudioStore.StoreState.StereoConfiguration.Playout {
        .init(
            preferred: preferred,
            enabled: enabled
        )
    }
}

extension RTCAudioStore.StoreState {

    static func dummy(
        isActive: Bool = false,
        isInterrupted: Bool = false,
        isRecording: Bool = false,
        isMicrophoneMuted: Bool = false,
        hasRecordingPermission: Bool = false,
        audioDeviceModule: AudioDeviceModule? = nil,
        currentRoute: AudioRoute = .dummy(),
        audioSessionConfiguration: AVAudioSessionConfiguration = .dummy(),
        webRTCAudioSessionConfiguration: WebRTCAudioSessionConfiguration = .dummy(),
        stereoConfiguration: StereoConfiguration = .dummy()
    ) -> RTCAudioStore.StoreState {
        .init(
            isActive: isActive,
            isInterrupted: isInterrupted,
            isRecording: isRecording,
            isMicrophoneMuted: isMicrophoneMuted,
            hasRecordingPermission: hasRecordingPermission,
            audioDeviceModule: audioDeviceModule,
            currentRoute: currentRoute,
            audioSessionConfiguration: audioSessionConfiguration,
            webRTCAudioSessionConfiguration: webRTCAudioSessionConfiguration,
            stereoConfiguration: stereoConfiguration
        )
    }
}
