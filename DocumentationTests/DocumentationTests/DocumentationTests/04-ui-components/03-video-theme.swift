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
        let streamBlue = UIColor(red: 0, green: 108.0 / 255.0, blue: 255.0 / 255.0, alpha: 1)
        var colors = Colors()
        colors.tintColor = Color(streamBlue)
        let appearance = Appearance(colors: colors)
        let streamVideo = StreamVideoUI(streamVideo: streamVideo, appearance: appearance)
    }

    container {
        var images = Images()
        images.hangup = Image("your_custom_hangup_icon")
        let appearance = Appearance(images: images)
        let streamVideoUI = StreamVideoUI(streamVideo: streamVideo, appearance: appearance)
    }

    container {
        var fonts = Fonts()
        fonts.footnoteBold = Font.footnote
        let appearance = Appearance(fonts: fonts)
        let streamVideoUI = StreamVideoUI(streamVideo: streamVideo, appearance: appearance)
    }

    container {
        let sounds = Sounds()
        sounds.incomingCallSound = "your_custom_sound"
        let appearance = Appearance(sounds: sounds)
        let streamVideoUI = StreamVideoUI(streamVideo: streamVideo, appearance: appearance)
    }
}
