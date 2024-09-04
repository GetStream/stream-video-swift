import StreamVideo
import StreamVideoSwiftUI
import SwiftUI
import Combine
import AVFoundation

@MainActor
fileprivate func content() {
    asyncContainer {
        try await call.zoom(by: 1.5)
    }
}
