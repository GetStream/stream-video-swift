//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
import StreamWebRTC

extension RTCAudioStore {
    struct State: Equatable {

        var isActive: Bool
        var isInterrupted: Bool
        var prefersNoInterruptionsFromSystemAlerts: Bool
        var isAudioEnabled: Bool
        var useManualAudio: Bool
        var category: AVAudioSession.Category
        var mode: AVAudioSession.Mode
        var options: AVAudioSession.CategoryOptions
        var overrideOutputAudioPort: AVAudioSession.PortOverride
        var hasRecordingPermission: Bool

        static let initial = State(
            isActive: false,
            isInterrupted: false,
            prefersNoInterruptionsFromSystemAlerts: true,
            isAudioEnabled: false,
            useManualAudio: false,
            category: .playAndRecord,
            mode: .voiceChat,
            options: .allowBluetooth,
            overrideOutputAudioPort: .none,
            hasRecordingPermission: false
        )
    }
}
