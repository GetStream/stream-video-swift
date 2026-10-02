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
        @Injected(\.videoAppearance.colors) var colors
        @Injected(\.videoAppearance.images) var images
        @Injected(\.videoAppearance.sounds) var sounds
        @Injected(\.utils) var utils
    }

    container {
        @Injected(\.customType) var customType
    }
}
