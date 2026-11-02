//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo

@MainActor
private func content() {
    asyncContainer {
        let call = streamVideo.call(callType: "default", callId: "123")
        try await call.join()
        try await call.microphone.setAudioBitrateProfile(.musicHighQuality)
    }

    asyncContainer {
        try await call.microphone.setAudioBitrateProfile(.voiceStandard)
    }

    asyncContainer {
        try await call.microphone.setAudioBitrateProfile(.voiceHighQuality)
    }

    container {
        let profileSubscription = call.microphone.$audioBitrateProfile
            .sink { profile in
                let isMusicModeEnabled = profile == .musicHighQuality
                print("Music mode enabled: \(isMusicModeEnabled)")
            }
        _ = profileSubscription
    }
}
