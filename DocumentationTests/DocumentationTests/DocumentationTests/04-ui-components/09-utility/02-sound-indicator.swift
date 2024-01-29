import StreamVideo
import StreamVideoSwiftUI
import SwiftUI
import Combine

@MainActor
fileprivate func content() {
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
