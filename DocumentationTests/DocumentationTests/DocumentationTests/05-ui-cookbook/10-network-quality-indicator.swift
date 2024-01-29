import StreamVideo
import StreamVideoSwiftUI
import SwiftUI
import Combine

@MainActor
fileprivate func content() {
    viewContainer {
        ConnectionQualityIndicator(connectionQuality: participant.connectionQuality)
    }
}
