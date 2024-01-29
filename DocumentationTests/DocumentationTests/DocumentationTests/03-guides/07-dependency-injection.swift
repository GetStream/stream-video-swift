import StreamVideo
import StreamVideoSwiftUI
import SwiftUI
import Combine

@MainActor
fileprivate func content() {
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
