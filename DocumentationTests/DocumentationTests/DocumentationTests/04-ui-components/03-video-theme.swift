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
        let tokens = DesignSystemTokens()
        tokens.colors.accentPrimary = .red
        let appearance = VideoAppearance(tokens: tokens)
        appearance.colors.indicatorSoundIndicatorSpeaking = .green
    }

    container {
        let streamBlue = UIColor(red: 0, green: 108.0 / 255.0, blue: 255.0 / 255.0, alpha: 1)
        let tokens = DesignSystemTokens()
        tokens.colors.accentPrimary = streamBlue
        let videoAppearance = VideoAppearance(tokens: tokens)
        let streamVideo = StreamVideoUI(streamVideo: streamVideo, videoAppearance: videoAppearance)
    }

    container {
        let images = Images()
        images.hangup = Image("your_custom_hangup_icon")
        let videoAppearance = VideoAppearance(images: images)
        let streamVideoUI = StreamVideoUI(streamVideo: streamVideo, videoAppearance: videoAppearance)
    }

    container {
        let tokens = DesignSystemTokens()
        tokens.fonts.footnoteBold = Font.footnote
        let videoAppearance = VideoAppearance(tokens: tokens)
        let streamVideoUI = StreamVideoUI(streamVideo: streamVideo, videoAppearance: videoAppearance)
    }

    container {
        let sounds = Sounds()
        sounds.incomingCallSound = "your_custom_sound"
        let videoAppearance = VideoAppearance(sounds: sounds)
        let streamVideoUI = StreamVideoUI(streamVideo: streamVideo, videoAppearance: videoAppearance)
    }
}
