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
        @Injected(\.fonts) var fonts
        @Injected(\.colors) var colors
        @Injected(\.images) var images
        @Injected(\.sounds) var sounds
        @Injected(\.utils) var utils
    }

    container {
        @Injected(\.customType) var customType
    }
}
