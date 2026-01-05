//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

@MainActor
private func content() {
    container {
        SoundIndicator(participant: participant)
    }

    container {
        let images = Images()
        images.micTurnOn = Image("custom_mic_turn_on_icon")
        images.micTurnOff = Image("custom_mic_turn_off_icon")
        let appearance = Appearance(images: images)
        streamVideoUI = StreamVideoUI(streamVideo: streamVideo, appearance: appearance)
    }
}
