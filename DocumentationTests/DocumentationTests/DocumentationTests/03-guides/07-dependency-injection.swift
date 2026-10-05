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
        @Injected(\.streamVideo) var streamVideo
        @Injected(\.videoAppearance) var videoAppearance
        @Injected(\.colors) var colors
        @Injected(\.images) var images
        @Injected(\.fonts) var fonts
        @Injected(\.layout) var layout
        @Injected(\.videoAppearance.sounds) var sounds
        @Injected(\.utils) var utils
    }

    container {
        // In a file that also imports the Chat SDK.
        @Injected(\.videoAppearance.colors) var videoColors
        @Injected(\.videoAppearance.tokens.colors) var colors
        @Injected(\.videoAppearance.tokens.fonts) var fonts
        @Injected(\.videoAppearance.tokens.layout) var layout
    }

    container {
        @Injected(\.customType) var customType
    }
}
